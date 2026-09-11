#include "requests.hpp"

#include <qjsvalueiterator.h>
#include <qloggingcategory.h>
#include <qnetworkaccessmanager.h>
#include <qnetworkcookiejar.h>
#include <qnetworkreply.h>
#include <qnetworkrequest.h>

Q_LOGGING_CATEGORY(lcRequests, "caelestia.requests", QtInfoMsg)

namespace caelestia {

Requests::Requests(QObject* parent)
    : QObject(parent)
    , m_manager(new QNetworkAccessManager(this)) {}

Requests::~Requests() {
    // Disconnect and abort any in-flight replies before m_manager is torn down. Without this,
    // a shell reload can destroy the manager while a socket read is still pending, and the
    // completion later lands on a reply/socket whose vtable has already collapsed to its base
    // class, aborting the process with a pure virtual function call. Disconnecting first also
    // stops the finished callback from calling into a JS engine that may already be dying.
    const auto pending = m_pendingReplies;
    for (auto it = pending.constBegin(); it != pending.constEnd(); ++it) {
        QObject::disconnect(it.value());
        it.key()->abort();
        it.key()->deleteLater();
    }
    m_pendingReplies.clear();
}

void Requests::get(const QUrl& url, QJSValue onSuccess, QJSValue onError, QJSValue headers) const {
    if (!onSuccess.isCallable()) {
        qCWarning(lcRequests) << "get: onSuccess is not callable";
        return;
    }

    QNetworkRequest request(url);
    request.setAttribute(QNetworkRequest::CacheLoadControlAttribute, QNetworkRequest::AlwaysNetwork);
    request.setAttribute(QNetworkRequest::CookieSaveControlAttribute, QNetworkRequest::Manual);
    request.setRawHeader("Cache-Control", "no-cache, no-store");
    request.setRawHeader("Pragma", "no-cache");
    request.setRawHeader("Connection", "close");

    if (headers.isObject()) {
        QJSValueIterator it(headers);
        while (it.hasNext()) {
            it.next();
            request.setRawHeader(it.name().toUtf8(), it.value().toString().toUtf8());
        }
    }

    auto reply = m_manager->get(request);

    const auto connection = QObject::connect(reply, &QNetworkReply::finished, [this, reply, onSuccess, onError]() {
        m_pendingReplies.remove(reply);

        if (reply->error() == QNetworkReply::NoError) {
            onSuccess.call({ QString(reply->readAll()) });
        } else if (onError.isCallable()) {
            onError.call({ reply->errorString() });
        } else {
            qCWarning(lcRequests) << "get: request failed with error" << reply->errorString();
        }

        reply->deleteLater();
    });
    m_pendingReplies.insert(reply, connection);
}

void Requests::resetCookies() const {
    m_manager->setCookieJar(new QNetworkCookieJar(m_manager));
}

} // namespace caelestia
