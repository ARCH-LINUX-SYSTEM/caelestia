#pragma once

#include "backgroundwidgetsconfig.hpp"
#include "configobject.hpp"

#include <qstring.h>

namespace caelestia::config {

class DesktopClockBackground : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, false)
    CONFIG_PROPERTY(qreal, opacity, 0.7)
    CONFIG_PROPERTY(bool, blur, true)

public:
    explicit DesktopClockBackground(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addRangeConstraint(QStringLiteral("opacity"), 0, 1);
    }
};

class DesktopClockShadow : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(qreal, opacity, 0.7)
    CONFIG_PROPERTY(qreal, blur, 0.4)

public:
    explicit DesktopClockShadow(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addRangeConstraint(QStringLiteral("opacity"), 0, 1);
        addRangeConstraint(QStringLiteral("blur"), 0, 1);
    }
};

class DesktopClock : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, false)
    CONFIG_PROPERTY(bool, showOnlyWhenLocked, false)
    CONFIG_PROPERTY(QString, placementStrategy, QStringLiteral("leastBusy"))
    CONFIG_PROPERTY(qreal, x, 100)
    CONFIG_PROPERTY(qreal, y, 100)
    CONFIG_PROPERTY(QString, style, QStringLiteral("cookie"))
    CONFIG_PROPERTY(QString, styleLocked, QStringLiteral("cookie"))
    CONFIG_PROPERTY(qreal, scale, 1.0)
    CONFIG_PROPERTY(QString, position, QStringLiteral("bottom-right"))
    CONFIG_PROPERTY(bool, invertColors, false)
    CONFIG_SUBOBJECT(ClockCookieConfig, cookie)
    CONFIG_SUBOBJECT(DigitalClockConfig, digital)
    CONFIG_SUBOBJECT(ClockQuoteConfig, quote)
    CONFIG_SUBOBJECT(DesktopClockBackground, background)
    CONFIG_SUBOBJECT(DesktopClockShadow, shadow)

public:
    explicit DesktopClock(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_cookie(new ClockCookieConfig(this))
        , m_digital(new DigitalClockConfig(this))
        , m_quote(new ClockQuoteConfig(this))
        , m_background(new DesktopClockBackground(this))
        , m_shadow(new DesktopClockShadow(this)) {
        addEnumConstraint(QStringLiteral("placementStrategy"),
            { QStringLiteral("free"), QStringLiteral("leastBusy"), QStringLiteral("mostBusy") });
        addEnumConstraint(
            QStringLiteral("style"), { QStringLiteral("cookie"), QStringLiteral("digital") });
        addEnumConstraint(
            QStringLiteral("styleLocked"), { QStringLiteral("cookie"), QStringLiteral("digital") });
        addEnumConstraint(QStringLiteral("position"),
            { QStringLiteral("top-left"), QStringLiteral("top-center"), QStringLiteral("top-right"),
                QStringLiteral("middle-left"), QStringLiteral("middle-center"),
                QStringLiteral("middle-right"), QStringLiteral("bottom-left"),
                QStringLiteral("bottom-center"), QStringLiteral("bottom-right") });
        addRangeConstraint(QStringLiteral("scale"), 0.1, 5);
    }
};

class BackgroundVisualiser : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, false)
    CONFIG_PROPERTY(bool, autoHide, true)
    CONFIG_PROPERTY(bool, blur, false)
    CONFIG_PROPERTY(qreal, rounding, 1)
    CONFIG_PROPERTY(qreal, spacing, 1)
    CONFIG_PROPERTY(QString, placementStrategy, QStringLiteral("free"))
    CONFIG_PROPERTY(qreal, x, 0)
    CONFIG_PROPERTY(qreal, y, 0)

public:
    explicit BackgroundVisualiser(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addRangeConstraint(QStringLiteral("rounding"), 0, 10);
        addRangeConstraint(QStringLiteral("spacing"), 0, 10);
        addEnumConstraint(QStringLiteral("placementStrategy"),
            { QStringLiteral("free"), QStringLiteral("leastBusy"), QStringLiteral("mostBusy") });
    }
};

class BackgroundConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(bool, wallpaperEnabled, true)
    CONFIG_PROPERTY(bool, widgetsLocked, false)
    CONFIG_SUBOBJECT(DesktopClock, desktopClock)
    CONFIG_SUBOBJECT(BackgroundVisualiser, visualiser)
    CONFIG_SUBOBJECT(DesktopWidgetsConfig, widgets)
    CONFIG_PROPERTY(QStringList, screenList)
    CONFIG_PROPERTY(QString, wallpaperPath)
    CONFIG_PROPERTY(bool, centeredWallpaper, false)
    CONFIG_PROPERTY(QString, centeredWallpaperShape, QStringLiteral("Cookie7Sided"))
    CONFIG_PROPERTY(int, centeredWallpaperSize, 400)
    CONFIG_PROPERTY(QString, centeredWallpaperColor, QStringLiteral("primaryContainer"))
    CONFIG_PROPERTY(bool, centeredWallpaperOnlyWhenLocked, false)
    CONFIG_PROPERTY(QString, wallpaperAnimation, QStringLiteral("magic"))
    CONFIG_PROPERTY(QString, thumbnailPath)
    CONFIG_PROPERTY(bool, hideWhenFullscreen, true)
    CONFIG_PROPERTY(bool, videoWallpaperAutoplay, true)
    CONFIG_SUBOBJECT(BackgroundParallaxConfig, parallax)

public:
    explicit BackgroundConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_desktopClock(new DesktopClock(this))
        , m_visualiser(new BackgroundVisualiser(this))
        , m_widgets(new DesktopWidgetsConfig(this))
        , m_parallax(new BackgroundParallaxConfig(this)) {
        addRangeConstraint(QStringLiteral("centeredWallpaperSize"), 400, 800);
        addEnumConstraint(QStringLiteral("wallpaperAnimation"),
            { QString(), QStringLiteral("circleSelect"), QStringLiteral("circlePit"),
                QStringLiteral("magic"), QStringLiteral("Doom"), QStringLiteral("Peel"),
                QStringLiteral("transition"), QStringLiteral("pixelate"), QStringLiteral("stripes"),
                QStringLiteral("random") });
    }
};

} // namespace caelestia::config
