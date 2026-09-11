#pragma once

#include "configobject.hpp"

namespace caelestia::config {

class ProfileConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(QString, avatarPath)
    CONFIG_GLOBAL_PROPERTY(QString, avatarPicture)
    CONFIG_GLOBAL_PROPERTY(QString, descriptionText, QStringLiteral("::distro::"))

public:
    explicit ProfileConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

} // namespace caelestia::config
