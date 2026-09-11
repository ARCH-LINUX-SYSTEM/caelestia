#pragma once

#include <qhash.h>
#include <qnetworkaccessmanager.h>
#include <qobject.h>
#include <qqmlengine.h>

class QNetworkReply;

namespace caelestia {

class Requests : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit Requests(QObject* parent = nullptr);
    ~Requests() override;

    Q_INVOKABLE void get(
        const QUrl& url, QJSValue callback, QJSValue onError = QJSValue(), QJSValue headers = QJSValue()) const;
    Q_INVOKABLE void resetCookies() const;

private:
    QNetworkAccessManager* m_manager;
    // Tracked so in-flight replies can be disconnected and aborted before m_manager is torn
    // down (e.g. on shell reload), avoiding a socket read completion landing on a
    // partially-destroyed reply, or a finished callback firing into a dying JS engine.
    mutable QHash<QNetworkReply*, QMetaObject::Connection> m_pendingReplies;
};

} // namespace caelestia
