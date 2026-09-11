#pragma once

#include "configobject.hpp"

#include <qstring.h>
#include <qstringlist.h>
#include <qvariant.h>

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

class BarScrollActions : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, workspaces, true)
    CONFIG_PROPERTY(bool, volume, true)
    CONFIG_PROPERTY(bool, brightness, true)

public:
    explicit BarScrollActions(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BarPopouts : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, activeWindow, true)
    CONFIG_PROPERTY(bool, tray, true)
    CONFIG_PROPERTY(bool, statusIcons, true)

public:
    explicit BarPopouts(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BarShowWhenPressingSuper : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enable, true)
    CONFIG_PROPERTY(int, delay, 140)

public:
    explicit BarShowWhenPressingSuper(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addRangeConstraint(QStringLiteral("delay"), 0, 5000);
    }
};

class BarAutoHide : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enable, false)
    CONFIG_PROPERTY(int, hoverRegionWidth, 2)
    CONFIG_PROPERTY(bool, pushWindows, false)
    CONFIG_SUBOBJECT(BarShowWhenPressingSuper, showWhenPressingSuper)

public:
    explicit BarAutoHide(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_showWhenPressingSuper(new BarShowWhenPressingSuper(this)) {
        addRangeConstraint(QStringLiteral("hoverRegionWidth"), 0, 100);
    }
};

class BarResources : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(QString, style, u"filled"_s)
    CONFIG_PROPERTY(bool, showValue, false)
    CONFIG_PROPERTY(bool, alwaysShowSwap, false)
    CONFIG_PROPERTY(bool, alwaysShowCpu, true)
    CONFIG_PROPERTY(bool, alwaysShowCpuTemp, false)
    CONFIG_PROPERTY(bool, alwaysShowDisk, false)
    CONFIG_PROPERTY(bool, alwaysShowRam, true)
    CONFIG_PROPERTY(int, memoryWarningThreshold, 95)
    CONFIG_PROPERTY(int, swapWarningThreshold, 85)
    CONFIG_PROPERTY(int, cpuWarningThreshold, 90)

public:
    explicit BarResources(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addEnumConstraint(QStringLiteral("style"), { QStringLiteral("filled"), QStringLiteral("outline") });
        addRangeConstraint(QStringLiteral("memoryWarningThreshold"), 0, 100);
        addRangeConstraint(QStringLiteral("swapWarningThreshold"), 0, 100);
        addRangeConstraint(QStringLiteral("cpuWarningThreshold"), 0, 100);
    }
};

class BarLayouts : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(QStringList, leftLayout, { u"workspaces"_s })
    CONFIG_PROPERTY(QStringList, middleLayout, { u"clockWidget"_s })
    CONFIG_PROPERTY(QStringList, rightLayout, { u"systemIcons"_s })

public:
    explicit BarLayouts(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BarUtilButtons : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, showScreenSnip, true)
    CONFIG_PROPERTY(bool, showColorPicker, false)
    CONFIG_PROPERTY(bool, showMicToggle, false)
    CONFIG_PROPERTY(bool, showKeyboardToggle, true)
    CONFIG_PROPERTY(bool, showWallpaperToggle, false)
    CONFIG_PROPERTY(bool, showDarkModeToggle, true)
    CONFIG_PROPERTY(bool, showPerformanceProfileToggle, false)
    CONFIG_PROPERTY(bool, showScreenRecord, false)
    CONFIG_PROPERTY(bool, isRecording, false)

public:
    explicit BarUtilButtons(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BarWorkspaces : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(int, shown, 5)
    CONFIG_PROPERTY(bool, activeIndicator, true)
    CONFIG_PROPERTY(bool, occupiedBg, false)
    CONFIG_PROPERTY(bool, showWindows, true)
    CONFIG_PROPERTY(bool, showWindowsOnSpecialWorkspaces, true)
    CONFIG_PROPERTY(int, maxWindowIcons, 5)
    CONFIG_PROPERTY(bool, activeTrail, false)
    CONFIG_GLOBAL_PROPERTY(bool, perMonitorWorkspaces, true)
    CONFIG_PROPERTY(QString, label, u"  "_s)
    CONFIG_PROPERTY(QString, occupiedLabel, u"󰮯"_s)
    CONFIG_PROPERTY(QString, activeLabel, u"󰮯"_s)
    CONFIG_PROPERTY(QString, capitalisation, u"preserve"_s)
    CONFIG_PROPERTY(bool, monochromeIcons, true)
    CONFIG_PROPERTY(bool, showAppIcons, true)
    CONFIG_PROPERTY(QString, indicatorStyle, u"dot"_s)
    CONFIG_PROPERTY(bool, alwaysShowNumbers, false)
    CONFIG_PROPERTY(int, showNumberDelay, 300)
    CONFIG_PROPERTY(QStringList, numberMap, { u"1"_s, u"2"_s })
    CONFIG_PROPERTY(bool, useNerdFont, false)
    CONFIG_GLOBAL_PROPERTY(QVariantList, specialWorkspaceIcons)
    CONFIG_GLOBAL_PROPERTY(QVariantList, windowIcons,
        { vmap({
            { u"regex"_s, u"steam(_app_(default|[0-9]+))?"_s },
            { u"icon"_s, u"sports_esports"_s },
        }) })

public:
    explicit BarWorkspaces(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addRangeConstraint(QStringLiteral("shown"), 1, 30);
        addRangeConstraint(QStringLiteral("maxWindowIcons"), 0, 30);
        addRangeConstraint(QStringLiteral("showNumberDelay"), 0, 10000);
        addEnumConstraint(QStringLiteral("capitalisation"),
            { QStringLiteral("preserve"), QStringLiteral("upper"), QStringLiteral("lower") });
        addEnumConstraint(QStringLiteral("indicatorStyle"), { QStringLiteral("dot"), QStringLiteral("icon") });
    }
};

class BarActiveWindow : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, compact, false)
    CONFIG_PROPERTY(bool, inverted, false)
    CONFIG_PROPERTY(bool, showOnHover, true)

public:
    explicit BarActiveWindow(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BarTray : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, background, false)
    CONFIG_PROPERTY(bool, recolour, false)
    CONFIG_PROPERTY(bool, compact, false)
    CONFIG_PROPERTY(bool, showItemId, false)
    CONFIG_PROPERTY(bool, invertPinnedItems, true)
    CONFIG_PROPERTY(QStringList, pinnedItems, { u"Fcitx"_s })
    CONFIG_PROPERTY(bool, filterPassive, true)
    CONFIG_GLOBAL_PROPERTY(QVariantList, iconSubs)
    CONFIG_GLOBAL_PROPERTY(QStringList, hiddenIcons)

public:
    explicit BarTray(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BarStatus : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, showAudio, false)
    CONFIG_PROPERTY(bool, showMicrophone, false)
    CONFIG_PROPERTY(bool, showKbLayout, false)
    CONFIG_PROPERTY(bool, showNetwork, true)
    CONFIG_PROPERTY(bool, showWifi, true)
    CONFIG_PROPERTY(bool, showBluetooth, true)
    CONFIG_PROPERTY(bool, showBattery, true)
    CONFIG_PROPERTY(bool, showLockStatus, true)

public:
    explicit BarStatus(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BarClock : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, background, false)
    CONFIG_PROPERTY(bool, showDate, false)
    CONFIG_PROPERTY(bool, showIcon, true)

public:
    explicit BarClock(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BarWeather : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enable, false)
    CONFIG_PROPERTY(bool, enableGPS, true)
    CONFIG_PROPERTY(QString, city)
    CONFIG_PROPERTY(bool, useUSCS, false)
    CONFIG_PROPERTY(int, fetchInterval, 10)

public:
    explicit BarWeather(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addRangeConstraint(QStringLiteral("fetchInterval"), 5, 1440);
    }
};

class BarNotificationIndicators : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, showUnreadCount, false)

public:
    explicit BarNotificationIndicators(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BarIndicators : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_SUBOBJECT(BarNotificationIndicators, notifications)

public:
    explicit BarIndicators(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_notifications(new BarNotificationIndicators(this)) {}
};

class BarTooltips : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, clickToShow, false)

public:
    explicit BarTooltips(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BarMedia : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(QString, preferredPlayer)
    CONFIG_PROPERTY(bool, alwaysVisible, false)
    CONFIG_PROPERTY(bool, onlyTitle, false)

public:
    explicit BarMedia(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BarConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, persistent, true)
    CONFIG_PROPERTY(bool, showOnHover, true)
    CONFIG_PROPERTY(int, dragThreshold, 20)
    CONFIG_SUBOBJECT(BarAutoHide, autoHide)
    CONFIG_PROPERTY(bool, bottom, false)
    CONFIG_PROPERTY(int, cornerStyle, 0)
    CONFIG_PROPERTY(bool, floatStyleShadow, true)
    CONFIG_PROPERTY(QString, borderless, u"pills"_s)
    CONFIG_PROPERTY(QString, topLeftIcon, u"spark"_s)
    CONFIG_PROPERTY(bool, showBackground, true)
    CONFIG_PROPERTY(bool, verbose, true)
    CONFIG_PROPERTY(bool, vertical, false)
    CONFIG_SUBOBJECT(BarResources, resources)
    CONFIG_SUBOBJECT(BarLayouts, layouts)
    CONFIG_PROPERTY(QStringList, screenList)
    CONFIG_SUBOBJECT(BarUtilButtons, utilButtons)
    CONFIG_SUBOBJECT(BarScrollActions, scrollActions)
    CONFIG_SUBOBJECT(BarPopouts, popouts)
    CONFIG_SUBOBJECT(BarWorkspaces, workspaces)
    CONFIG_SUBOBJECT(BarActiveWindow, activeWindow)
    CONFIG_SUBOBJECT(BarTray, tray)
    CONFIG_SUBOBJECT(BarStatus, status)
    CONFIG_SUBOBJECT(BarClock, clock)
    CONFIG_SUBOBJECT(BarWeather, weather)
    CONFIG_SUBOBJECT(BarIndicators, indicators)
    CONFIG_SUBOBJECT(BarTooltips, tooltips)
    CONFIG_SUBOBJECT(BarMedia, media)
    CONFIG_PROPERTY(QVariantList, entries,
        {
            vmap({ { u"id"_s, u"logo"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"workspaces"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"spacer"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"activeWindow"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"spacer"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"tray"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"clock"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"resources"_s }, { u"enabled"_s, false } }),
            vmap({ { u"id"_s, u"weather"_s }, { u"enabled"_s, false } }),
            vmap({ { u"id"_s, u"statusIcons"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"power"_s }, { u"enabled"_s, true } }),
        })
    CONFIG_PROPERTY(QStringList, excludedScreens)

public:
    explicit BarConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_autoHide(new BarAutoHide(this))
        , m_resources(new BarResources(this))
        , m_layouts(new BarLayouts(this))
        , m_utilButtons(new BarUtilButtons(this))
        , m_scrollActions(new BarScrollActions(this))
        , m_popouts(new BarPopouts(this))
        , m_workspaces(new BarWorkspaces(this))
        , m_activeWindow(new BarActiveWindow(this))
        , m_tray(new BarTray(this))
        , m_status(new BarStatus(this))
        , m_clock(new BarClock(this))
        , m_weather(new BarWeather(this))
        , m_indicators(new BarIndicators(this))
        , m_tooltips(new BarTooltips(this))
        , m_media(new BarMedia(this)) {
        addRangeConstraint(QStringLiteral("dragThreshold"), 0, 200);
        addRangeConstraint(QStringLiteral("cornerStyle"), 0, 3);
        addEnumConstraint(QStringLiteral("borderless"),
            { QStringLiteral("transparent"), QStringLiteral("pills"), QStringLiteral("separated") });
    }
};

} // namespace caelestia::config
