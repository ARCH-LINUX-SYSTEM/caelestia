#pragma once

#include "configobject.hpp"

#include <qstring.h>

namespace caelestia::config {

class NotifsConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(bool, expire, true)
    CONFIG_GLOBAL_PROPERTY(QString, fullscreen, QStringLiteral("on"))
    CONFIG_GLOBAL_PROPERTY(int, defaultExpireTimeout, 5000)
    CONFIG_GLOBAL_PROPERTY(int, fullscreenExpireTimeout, 2000)
    CONFIG_PROPERTY(qreal, clearThreshold, 0.3)
    CONFIG_PROPERTY(int, expandThreshold, 20)
    CONFIG_GLOBAL_PROPERTY(bool, actionOnClick, false)
    CONFIG_PROPERTY(int, groupPreviewNum, 3)
    CONFIG_PROPERTY(bool, openExpanded, false)

public:
    explicit NotifsConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addEnumConstraint(
            QStringLiteral("fullscreen"), { QStringLiteral("off"), QStringLiteral("on") });
        addRangeConstraint(QStringLiteral("defaultExpireTimeout"), 0, 600000);
        addRangeConstraint(QStringLiteral("fullscreenExpireTimeout"), 0, 600000);
        addRangeConstraint(QStringLiteral("clearThreshold"), 0, 1);
        addRangeConstraint(QStringLiteral("expandThreshold"), 0, 1000);
        addRangeConstraint(QStringLiteral("groupPreviewNum"), 1, 100);
    }
};

} // namespace caelestia::config
