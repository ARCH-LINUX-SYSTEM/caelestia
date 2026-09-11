#pragma once

#include "configobject.hpp"

namespace caelestia::config {

class WindowsConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(bool, showTitlebar, true)
    CONFIG_GLOBAL_PROPERTY(bool, centerTitle, true)

public:
    explicit WindowsConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

} // namespace caelestia::config
