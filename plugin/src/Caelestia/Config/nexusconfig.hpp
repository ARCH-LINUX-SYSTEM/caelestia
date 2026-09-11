#pragma once

#include "configobject.hpp"

namespace caelestia::config {

class NexusConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(int, wallpapersPerRow, 4)
    CONFIG_GLOBAL_PROPERTY(int, networkRescanInterval, 15000)
    CONFIG_GLOBAL_PROPERTY(bool, useSystemFileDialog, false)
    CONFIG_GLOBAL_PROPERTY(bool, showWallpaperBlurBackground, false)
    CONFIG_GLOBAL_PROPERTY(bool, showWallpaperHomePath, true)
    CONFIG_GLOBAL_PROPERTY(QString, wallpaperUserPath)
    CONFIG_GLOBAL_PROPERTY(bool, showWallpaperSearch, true)
    CONFIG_GLOBAL_PROPERTY(bool, closeAfterWallpaperSelection, true)
    CONFIG_GLOBAL_PROPERTY(int, wallpaperChangeInterval, 0)

public:
    explicit NexusConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addRangeConstraint(QStringLiteral("wallpapersPerRow"), 3, 10);
        addRangeConstraint(QStringLiteral("networkRescanInterval"), 1000, 3600000);
        addRangeConstraint(QStringLiteral("wallpaperChangeInterval"), 0, 1440);
    }
};

} // namespace caelestia::config
