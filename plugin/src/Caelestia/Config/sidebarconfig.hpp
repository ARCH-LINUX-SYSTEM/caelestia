#pragma once

#include "configobject.hpp"

#include <qstring.h>

namespace caelestia::config {

class SidebarTranslatorConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enable, false)
    CONFIG_PROPERTY(int, delay, 300)

public:
    explicit SidebarTranslatorConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addRangeConstraint(QStringLiteral("delay"), 0, 10000);
    }
};

class SidebarMediaConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enable, true)
    CONFIG_PROPERTY(bool, artColors, false)

public:
    explicit SidebarMediaConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class SidebarAiConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, textFadeIn, false)

public:
    explicit SidebarAiConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class SidebarZerochanConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(QString, username, QStringLiteral("[unset]"))

public:
    explicit SidebarZerochanConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class SidebarBooruConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(bool, allowNsfw, false)
    CONFIG_GLOBAL_PROPERTY(QString, defaultProvider, QStringLiteral("yandere"))
    CONFIG_GLOBAL_PROPERTY(int, limit, 20)
    CONFIG_SUBOBJECT(SidebarZerochanConfig, zerochan)

public:
    explicit SidebarBooruConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_zerochan(new SidebarZerochanConfig(this)) {
        addRangeConstraint(QStringLiteral("limit"), 1, 100);
    }
};

class SidebarCornerOpenConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enable, true)
    CONFIG_PROPERTY(bool, bottom, false)
    CONFIG_PROPERTY(bool, valueScroll, true)
    CONFIG_PROPERTY(bool, clickless, false)
    CONFIG_PROPERTY(int, cornerRegionWidth, 250)
    CONFIG_PROPERTY(int, cornerRegionHeight, 5)
    CONFIG_PROPERTY(bool, visualize, false)
    CONFIG_PROPERTY(bool, clicklessCornerEnd, true)
    CONFIG_PROPERTY(int, clicklessCornerVerticalOffset, 1)

public:
    explicit SidebarCornerOpenConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addRangeConstraint(QStringLiteral("cornerRegionWidth"), 1, 2000);
        addRangeConstraint(QStringLiteral("cornerRegionHeight"), 1, 500);
        addRangeConstraint(QStringLiteral("clicklessCornerVerticalOffset"), -500, 500);
    }
};

class SidebarQuickSlidersConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enable, false)
    CONFIG_PROPERTY(bool, showMic, false)
    CONFIG_PROPERTY(bool, showVolume, true)
    CONFIG_PROPERTY(bool, showBrightness, true)

public:
    explicit SidebarQuickSlidersConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class SidebarConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(bool, showOnHover, false)
    CONFIG_PROPERTY(int, minHoverThreshold, 200)
    CONFIG_PROPERTY(int, dragThreshold, 80)
    CONFIG_PROPERTY(bool, banner, false)
    CONFIG_PROPERTY(QString, bannerImage)
    CONFIG_PROPERTY(bool, keepRightSidebarLoaded, true)
    CONFIG_SUBOBJECT(SidebarTranslatorConfig, translator)
    CONFIG_SUBOBJECT(SidebarMediaConfig, media)
    CONFIG_SUBOBJECT(SidebarAiConfig, ai)
    CONFIG_SUBOBJECT(SidebarBooruConfig, booru)
    CONFIG_SUBOBJECT(SidebarCornerOpenConfig, cornerOpen)
    CONFIG_SUBOBJECT(SidebarQuickSlidersConfig, quickSliders)

public:
    explicit SidebarConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_translator(new SidebarTranslatorConfig(this))
        , m_media(new SidebarMediaConfig(this))
        , m_ai(new SidebarAiConfig(this))
        , m_booru(new SidebarBooruConfig(this))
        , m_cornerOpen(new SidebarCornerOpenConfig(this))
        , m_quickSliders(new SidebarQuickSlidersConfig(this)) {
        addRangeConstraint(QStringLiteral("minHoverThreshold"), 0, 2000);
        addRangeConstraint(QStringLiteral("dragThreshold"), 0, 500);
    }
};

} // namespace caelestia::config
