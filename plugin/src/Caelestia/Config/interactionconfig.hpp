#pragma once

#include "configobject.hpp"

namespace caelestia::config {

class ScrollingConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(bool, fasterTouchpadScroll, false)
    CONFIG_GLOBAL_PROPERTY(int, mouseScrollDeltaThreshold, 120)
    CONFIG_GLOBAL_PROPERTY(int, mouseScrollFactor, 120)
    CONFIG_GLOBAL_PROPERTY(int, touchpadScrollFactor, 450)

public:
    explicit ScrollingConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addRangeConstraint(QStringLiteral("mouseScrollDeltaThreshold"), 1, 2000);
        addRangeConstraint(QStringLiteral("mouseScrollFactor"), 1, 5000);
        addRangeConstraint(QStringLiteral("touchpadScrollFactor"), 1, 5000);
    }
};

class DeadPixelWorkaroundConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(bool, enabled, false)

public:
    explicit DeadPixelWorkaroundConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class InteractionConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_SUBOBJECT(ScrollingConfig, scrolling)
    CONFIG_SUBOBJECT(DeadPixelWorkaroundConfig, deadPixelWorkaround)

public:
    explicit InteractionConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_scrolling(new ScrollingConfig(this))
        , m_deadPixelWorkaround(new DeadPixelWorkaroundConfig(this)) {}
};

class TranslatorConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(QString, engine, QStringLiteral("auto"))
    CONFIG_GLOBAL_PROPERTY(QString, targetLanguage, QStringLiteral("auto"))
    CONFIG_GLOBAL_PROPERTY(QString, sourceLanguage, QStringLiteral("auto"))

public:
    explicit TranslatorConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class LanguageConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(QString, ui, QStringLiteral("auto"))
    CONFIG_SUBOBJECT(TranslatorConfig, translator)

public:
    explicit LanguageConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_translator(new TranslatorConfig(this)) {}
};

class OverviewConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(bool, enabled, true)
    CONFIG_GLOBAL_PROPERTY(QString, style, QStringLiteral("default"))
    CONFIG_GLOBAL_PROPERTY(qreal, scale, 0.18)
    CONFIG_GLOBAL_PROPERTY(int, rows, 2)
    CONFIG_GLOBAL_PROPERTY(int, columns, 5)
    CONFIG_GLOBAL_PROPERTY(bool, orderRightLeft, false)
    CONFIG_GLOBAL_PROPERTY(bool, orderBottomUp, false)
    CONFIG_GLOBAL_PROPERTY(bool, centerIcons, true)

public:
    explicit OverviewConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addRangeConstraint(QStringLiteral("scale"), 0.01, 1);
        addRangeConstraint(QStringLiteral("rows"), 1, 20);
        addRangeConstraint(QStringLiteral("columns"), 1, 20);
    }
};

class TargetRegionsConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(bool, windows, true)
    CONFIG_GLOBAL_PROPERTY(bool, layers, false)
    CONFIG_GLOBAL_PROPERTY(bool, content, true)
    CONFIG_GLOBAL_PROPERTY(bool, showLabel, false)
    CONFIG_GLOBAL_PROPERTY(qreal, opacity, 0.3)
    CONFIG_GLOBAL_PROPERTY(qreal, contentRegionOpacity, 0.8)
    CONFIG_GLOBAL_PROPERTY(int, selectionPadding, 5)

public:
    explicit TargetRegionsConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addRangeConstraint(QStringLiteral("opacity"), 0, 1);
        addRangeConstraint(QStringLiteral("contentRegionOpacity"), 0, 1);
        addRangeConstraint(QStringLiteral("selectionPadding"), 0, 100);
    }
};

class RegionRectConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(bool, showAimLines, true)

public:
    explicit RegionRectConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class RegionCircleConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(int, strokeWidth, 6)
    CONFIG_GLOBAL_PROPERTY(int, padding, 10)

public:
    explicit RegionCircleConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addRangeConstraint(QStringLiteral("strokeWidth"), 1, 20);
        addRangeConstraint(QStringLiteral("padding"), 0, 100);
    }
};

class RegionAnnotationConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(bool, useSatty, false)

public:
    explicit RegionAnnotationConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class RegionSelectorConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_SUBOBJECT(TargetRegionsConfig, targetRegions)
    CONFIG_SUBOBJECT(RegionRectConfig, rect)
    CONFIG_SUBOBJECT(RegionCircleConfig, circle)
    CONFIG_SUBOBJECT(RegionAnnotationConfig, annotation)

public:
    explicit RegionSelectorConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_targetRegions(new TargetRegionsConfig(this))
        , m_rect(new RegionRectConfig(this))
        , m_circle(new RegionCircleConfig(this))
        , m_annotation(new RegionAnnotationConfig(this)) {}
};

} // namespace caelestia::config
