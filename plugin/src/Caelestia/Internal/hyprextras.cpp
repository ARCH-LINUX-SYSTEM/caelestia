#include "hyprextras.hpp"
#include "hyprdevices.hpp"

#include <qdir.h>
#include <qjsonarray.h>
#include <qlocalsocket.h>
#include <qloggingcategory.h>
#include <qregularexpression.h>
#include <qtimer.h>
#include <qvariant.h>

#include <cmath>
#include <optional>

Q_LOGGING_CATEGORY(lcHypr, "caelestia.internal.hypr", QtInfoMsg)

namespace caelestia::internal::hypr {

namespace {

const QRegularExpression optionKeyPattern(
    QStringLiteral(R"(^[A-Za-z0-9_.-]+(?::[A-Za-z0-9_.-]+)*$)"));
const QRegularExpression numericTuplePattern(QStringLiteral(R"(^-?[0-9]+(?:\s+-?[0-9]+){0,3}$)"));

QString cssGapsLuaTable(const QString& tuple) {
    const auto values = tuple.split(QLatin1Char(' '));
    QString top;
    QString right;
    QString bottom;
    QString left;

    switch (values.size()) {
    case 1:
        top = right = bottom = left = values.at(0);
        break;
    case 2:
        top = bottom = values.at(0);
        right = left = values.at(1);
        break;
    case 3:
        top = values.at(0);
        right = left = values.at(1);
        bottom = values.at(2);
        break;
    case 4:
        top = values.at(0);
        right = values.at(1);
        bottom = values.at(2);
        left = values.at(3);
        break;
    default:
        return {};
    }

    return QStringLiteral("{ top = %1, right = %2, bottom = %3, left = %4 }")
        .arg(top, right, bottom, left);
}

std::optional<QString> optionLiteral(const QVariant& value, bool usingLua) {
    switch (value.metaType().id()) {
    case QMetaType::Bool:
        return value.toBool() ? QStringLiteral("true") : QStringLiteral("false");
    case QMetaType::Char:
    case QMetaType::SChar:
    case QMetaType::Short:
    case QMetaType::Int:
    case QMetaType::Long:
    case QMetaType::LongLong:
        return QString::number(value.toLongLong());
    case QMetaType::UChar:
    case QMetaType::UShort:
    case QMetaType::UInt:
    case QMetaType::ULong:
    case QMetaType::ULongLong:
        return QString::number(value.toULongLong());
    case QMetaType::Float:
    case QMetaType::Double: {
        const auto number = value.toDouble();
        if (!std::isfinite(number))
            return std::nullopt;
        return QString::number(number, 'g', 17);
    }
    case QMetaType::QString: {
        // Hyprland exposes custom gap values as one-to-four space-separated integers.
        // This deliberately rejects arbitrary strings so QML cannot inject socket commands or Lua.
        const auto tuple = value.toString().simplified();
        if (!numericTuplePattern.match(tuple).hasMatch())
            return std::nullopt;
        return usingLua ? cssGapsLuaTable(tuple) : tuple;
    }
    default:
        return std::nullopt;
    }
}

} // namespace

HyprExtras::HyprExtras(QObject* parent)
    : QObject(parent)
    , m_requestSocket("")
    , m_eventSocket("")
    , m_socket(nullptr)
    , m_socketValid(false)
    , m_devices(new HyprDevices(this)) {
    const auto his = qEnvironmentVariable("HYPRLAND_INSTANCE_SIGNATURE");
    if (his.isEmpty()) {
        qCWarning(lcHypr) << "$HYPRLAND_INSTANCE_SIGNATURE is unset. Unable to connect to Hyprland socket.";
        return;
    }

    auto hyprDir = QString("%1/hypr/%2").arg(qEnvironmentVariable("XDG_RUNTIME_DIR"), his);
    if (!QDir(hyprDir).exists()) {
        hyprDir = "/tmp/hypr/" + his;

        if (!QDir(hyprDir).exists()) {
            qCWarning(lcHypr) << "Hyprland socket directory does not exist. Unable to connect to Hyprland socket.";
            return;
        }
    }

    m_requestSocket = hyprDir + "/.socket.sock";
    m_eventSocket = hyprDir + "/.socket2.sock";

    refreshOptions();
    refreshDevices();

    m_socket = new QLocalSocket(this);

    QObject::connect(m_socket, &QLocalSocket::errorOccurred, this, &HyprExtras::socketError);
    QObject::connect(m_socket, &QLocalSocket::stateChanged, this, &HyprExtras::socketStateChanged);
    QObject::connect(m_socket, &QLocalSocket::readyRead, this, &HyprExtras::readEvent);

    m_socket->connectToServer(m_eventSocket, QLocalSocket::ReadOnly);
}

QVariantHash HyprExtras::options() const {
    return m_options;
}

HyprDevices* HyprExtras::devices() const {
    return m_devices;
}

void HyprExtras::message(const QString& message) {
    if (message.isEmpty()) {
        return;
    }

    makeRequest(message, [](bool success, const QByteArray& res) {
        if (!success) {
            qCWarning(lcHypr) << "message: request error:" << QString::fromUtf8(res);
        }
    });
}

void HyprExtras::batchMessage(const QStringList& messages) {
    if (messages.isEmpty()) {
        return;
    }

    makeRequest("[[BATCH]]" + messages.join(";"), [](bool success, const QByteArray& res) {
        if (!success) {
            qCWarning(lcHypr) << "batchMessage: request error:" << QString::fromUtf8(res);
        }
    });
}

void HyprExtras::applyOptions(const QVariantHash& options) {
    if (options.isEmpty()) {
        return;
    }

    QString request;
    request.reserve(12 + options.size() * 40);
    request += QLatin1String("[[BATCH]]");
    for (auto it = options.constBegin(); it != options.constEnd(); ++it) {
        if (!optionKeyPattern.match(it.key()).hasMatch()) {
            qCWarning(lcHypr) << "applyOptions: rejected invalid option key:" << it.key();
            continue;
        }
        if (it.value().metaType().id() == QMetaType::QString && it.key() != QLatin1String("general:gaps_in") &&
            it.key() != QLatin1String("general:gaps_out")) {
            qCWarning(lcHypr) << "applyOptions: string values are only supported for CSS gap options";
            continue;
        }

        const auto literal = optionLiteral(it.value(), m_usingLua);
        if (!literal) {
            qCWarning(lcHypr) << "applyOptions: rejected unsafe value for" << it.key();
            continue;
        }

        if (!m_usingLua) {
            request += QLatin1String("keyword ") + it.key() + QLatin1Char(' ') + *literal + QLatin1Char(';');
        } else {
            auto parts = it.key().split(':');
            request += "eval hl.config({ " + parts.join(" = { ") + " = " + *literal +
                       QString(" }").repeated(parts.size() - 1) + " });";
        }
    }

    if (request == QLatin1String("[[BATCH]]"))
        return;

    makeRequest(request, [this](bool success, const QByteArray& res) {
        if (success) {
            refreshOptions();
        } else {
            qCWarning(lcHypr) << "applyOptions: request error" << QString::fromUtf8(res);
        }
    });
}

void HyprExtras::refreshOptions() {
    const auto generation = ++m_optionsRefreshGeneration;
    if (!m_optionsRefresh.isNull()) {
        m_optionsRefresh->abort();
    }

    m_optionsRefresh = makeRequestJson("descriptions", [this, generation](bool success, const QJsonDocument& response) {
        if (generation != m_optionsRefreshGeneration) {
            return;
        }

        m_optionsRefresh.reset();
        if (!success) {
            return;
        }

        const auto options = response.array();
        bool dirty = false;

        for (const auto& o : std::as_const(options)) {
            const auto obj = o.toObject();
            const auto key = obj.value("value").toString();
            const auto value = obj.value("data").toObject().value("current").toVariant();
            if (m_options.value(key) != value) {
                dirty = true;
                m_options.insert(key, value);
            }
        }

        if (dirty) {
            emit optionsChanged();
        }
    });
}

void HyprExtras::refreshDevices() {
    const auto generation = ++m_devicesRefreshGeneration;
    if (!m_devicesRefresh.isNull()) {
        m_devicesRefresh->abort();
    }

    m_devicesRefresh = makeRequestJson("devices", [this, generation](bool success, const QJsonDocument& response) {
        if (generation != m_devicesRefreshGeneration) {
            return;
        }

        m_devicesRefresh.reset();
        if (success) {
            m_devices->updateLastIpcObject(response.object());
        }
    });
}

void HyprExtras::socketError(QLocalSocket::LocalSocketError error) const {
    if (!m_socketValid) {
        qCWarning(lcHypr) << "socketError: unable to connect to Hyprland event socket:" << error;
    } else {
        qCWarning(lcHypr) << "socketError: Hyprland event socket error:" << error;
    }
}

void HyprExtras::socketStateChanged(QLocalSocket::LocalSocketState state) {
    if (state == QLocalSocket::UnconnectedState && m_socketValid) {
        qCWarning(lcHypr) << "socketStateChanged: Hyprland event socket disconnected.";
    }

    m_socketValid = state == QLocalSocket::ConnectedState;
}

void HyprExtras::readEvent() {
    while (true) {
        auto rawEvent = m_socket->readLine();
        if (rawEvent.isEmpty()) {
            break;
        }
        rawEvent.truncate(rawEvent.length() - 1); // Remove trailing \n
        const auto event = QByteArrayView(rawEvent.data(), rawEvent.indexOf(">>"));
        handleEvent(QString::fromUtf8(event));
    }
}

void HyprExtras::handleEvent(const QString& event) {
    if (event == "configreloaded") {
        refreshOptions();
    } else if (event == "activelayout") {
        refreshDevices();
    }
}

HyprExtras::SocketPtr HyprExtras::makeRequestJson(
    const QString& request, const std::function<void(bool, QJsonDocument)>& callback) {
    return makeRequest("j/" + request, [request, callback](bool success, const QByteArray& response) {
        if (!success) {
            callback(false, {});
            return;
        }

        QJsonParseError error{};
        auto document = QJsonDocument::fromJson(response, &error);
        if (error.error != QJsonParseError::NoError || document.isNull()) {
            qCWarning(lcHypr) << "makeRequestJson: invalid response for" << request << ':' << error.errorString();
            callback(false, {});
            return;
        }

        callback(true, std::move(document));
    });
}

HyprExtras::SocketPtr HyprExtras::makeRequest(
    const QString& request, const std::function<void(bool, QByteArray)>& callback) {
    if (m_requestSocket.isEmpty()) {
        return SocketPtr();
    }

    // SocketPtr is the sole owner. Signal handlers keep fire-and-forget requests alive;
    // complete() disconnects them and the timer to break those reference cycles.
    auto socket = SocketPtr::create();
    auto completed = QSharedPointer<bool>::create(false);
    auto response = QSharedPointer<QByteArray>::create();
    auto completionTimer = QSharedPointer<QTimer>::create();
    completionTimer->setSingleShot(true);

    const auto complete = [this, socket, completionTimer, completed, callback](
                               bool success, QByteArray responseData) {
        if (*completed) {
            return;
        }

        *completed = true;

        // disconnected/errorOccurred call complete() synchronously from within Qt's own
        // socket-engine dispatch for this socket (QAbstractSocketPrivate::canReadNotification
        // is still on the stack). Tearing the socket down here (abort()) races that dispatch
        // and corrupts its in-progress state, so defer teardown to the next event loop turn.
        QTimer::singleShot(0, this,
            [socket, completionTimer, callback, success, responseData = std::move(responseData)]() mutable {
                QObject::disconnect(socket.data(), nullptr, nullptr, nullptr);
                QObject::disconnect(completionTimer.data(), nullptr, nullptr, nullptr);
                completionTimer->stop();
                socket->abort();
                callback(success, std::move(responseData));
            });
    };

    QObject::connect(completionTimer.data(), &QTimer::timeout, this, [request, response, complete]() {
        if (response->isEmpty())
            qCWarning(lcHypr) << "makeRequest: timed out waiting for response | request:" << request;
        complete(!response->isEmpty(), std::move(*response));
    });

    QObject::connect(socket.data(), &QLocalSocket::connected, this, [socket, request]() {
        socket->write(request.toUtf8());
        socket->flush();
    });

    QObject::connect(socket.data(), &QLocalSocket::readyRead, this, [socket, response, completionTimer]() {
        response->append(socket->readAll());
        // Hyprland normally closes the request socket after replying. The short
        // quiescence fallback also supports providers that leave it connected,
        // while allowing split local-socket writes to be accumulated first.
        completionTimer->start(50);
    });

    QObject::connect(socket.data(), &QLocalSocket::disconnected, this, [socket, response, complete]() {
        response->append(socket->readAll());
        complete(!response->isEmpty(), std::move(*response));
    });

    QObject::connect(
        socket.data(), &QLocalSocket::errorOccurred, this, [request, complete](QLocalSocket::LocalSocketError err) {
            qCWarning(lcHypr) << "makeRequest: error making request:" << err << "| request:" << request;
            complete(false, {});
        });

    // Bound fire-and-forget requests even if a provider neither replies nor
    // disconnects. readyRead switches this timer to the 50 ms settle window.
    completionTimer->start(2000);
    socket->connectToServer(m_requestSocket);

    return socket;
}

} // namespace caelestia::internal::hypr
