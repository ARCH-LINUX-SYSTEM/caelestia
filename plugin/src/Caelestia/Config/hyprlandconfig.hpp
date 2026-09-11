#pragma once

#include "configobject.hpp"

namespace caelestia::config {

class HyprlandAnimationsConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(QString, animation, QStringLiteral("normal"))
    CONFIG_GLOBAL_PROPERTY(bool, enabled, true)

public:
    explicit HyprlandAnimationsConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addEnumConstraint(QStringLiteral("animation"),
            { QStringLiteral("fast"), QStringLiteral("normal"), QStringLiteral("niri") });
    }
};

class HyprlandAutostartConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(bool, enabled, false)
    CONFIG_GLOBAL_PROPERTY(QVariantList, apps)

public:
    explicit HyprlandAutostartConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addValidator(QStringLiteral("apps"), [](const QVariant& value) {
            for (const auto& entry : value.toList()) {
                if (entry.metaType().id() == QMetaType::QString) {
                    if (entry.toString().trimmed().isEmpty())
                        return QStringLiteral("must not contain empty commands");
                    continue;
                }

                const auto app = entry.toMap();
                const auto command = app.value(QStringLiteral("command")).toString().trimmed();
                const auto legacyCommand = app.value(QStringLiteral("cmd")).toString().trimmed();
                if (app.isEmpty() || (command.isEmpty() && legacyCommand.isEmpty()))
                    return QStringLiteral("entries must be command strings or objects with command/cmd");
            }
            return QString();
        });
    }
};

class HyprlandBlurConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(bool, enabled, true)
    CONFIG_GLOBAL_PROPERTY(int, size, 1)
    CONFIG_GLOBAL_PROPERTY(int, passes, 3)

public:
    explicit HyprlandBlurConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addRangeConstraint(QStringLiteral("size"), 1, 20);
        addRangeConstraint(QStringLiteral("passes"), 1, 6);
    }
};

class HyprlandShadowConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(bool, enabled, true)
    CONFIG_GLOBAL_PROPERTY(int, range, 4)

public:
    explicit HyprlandShadowConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addRangeConstraint(QStringLiteral("range"), 0, 100);
    }
};

class HyprlandDecorationConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(int, rounding, 22)
    CONFIG_GLOBAL_PROPERTY(qreal, activeOpacity, 1)
    CONFIG_GLOBAL_PROPERTY(qreal, inactiveOpacity, 0.9)
    CONFIG_SUBOBJECT(HyprlandBlurConfig, blur)
    CONFIG_SUBOBJECT(HyprlandShadowConfig, shadow)

public:
    explicit HyprlandDecorationConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_blur(new HyprlandBlurConfig(this))
        , m_shadow(new HyprlandShadowConfig(this)) {
        addRangeConstraint(QStringLiteral("rounding"), 0, 30);
        addRangeConstraint(QStringLiteral("activeOpacity"), 0.1, 1);
        addRangeConstraint(QStringLiteral("inactiveOpacity"), 0.1, 1);
    }
};

class HyprlandGeneralConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(int, borderSize, 1)
    CONFIG_GLOBAL_PROPERTY(int, gapsIn, 2)
    CONFIG_GLOBAL_PROPERTY(int, gapsOut, 5)
    CONFIG_GLOBAL_PROPERTY(QString, layout, QStringLiteral("dwindle"))

public:
    explicit HyprlandGeneralConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addRangeConstraint(QStringLiteral("borderSize"), 0, 10);
        addRangeConstraint(QStringLiteral("gapsIn"), 0, 40);
        addRangeConstraint(QStringLiteral("gapsOut"), 0, 60);
        addEnumConstraint(QStringLiteral("layout"),
            { QStringLiteral("dwindle"), QStringLiteral("master"), QStringLiteral("scrolling") });
    }
};

class HyprlandTouchpadConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(bool, naturalScroll, false)
    CONFIG_GLOBAL_PROPERTY(bool, disableWhileTyping, true)
    CONFIG_GLOBAL_PROPERTY(bool, clickfingerBehavior, false)
    CONFIG_GLOBAL_PROPERTY(qreal, scrollFactor, 0.7)

public:
    explicit HyprlandTouchpadConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addRangeConstraint(QStringLiteral("scrollFactor"), 0.1, 3);
    }
};

class HyprlandInputConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(QString, kbLayout, QStringLiteral("us"))
    CONFIG_GLOBAL_PROPERTY(bool, numlock, true)
    CONFIG_GLOBAL_PROPERTY(int, repeatDelay, 250)
    CONFIG_GLOBAL_PROPERTY(int, repeatRate, 35)
    CONFIG_GLOBAL_PROPERTY(int, followMouse, 1)
    CONFIG_SUBOBJECT(HyprlandTouchpadConfig, touchpad)

public:
    explicit HyprlandInputConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_touchpad(new HyprlandTouchpadConfig(this)) {
        addRegexConstraint(QStringLiteral("kbLayout"),
            QRegularExpression(QStringLiteral("^[A-Za-z0-9_+,-]+$")),
            QStringLiteral("contains unsupported keyboard-layout characters"));
        addRangeConstraint(QStringLiteral("repeatDelay"), 100, 1000);
        addRangeConstraint(QStringLiteral("repeatRate"), 10, 100);
        addRangeConstraint(QStringLiteral("followMouse"), 0, 3);
    }
};

class HyprlandConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    // Caelestia safety gate. The 25 imported values do not alter Hyprland until enabled.
    CONFIG_GLOBAL_PROPERTY(bool, enabled, false)
    CONFIG_SUBOBJECT(HyprlandAnimationsConfig, animations)
    CONFIG_SUBOBJECT(HyprlandAutostartConfig, autostartApps)
    CONFIG_SUBOBJECT(HyprlandDecorationConfig, decoration)
    CONFIG_SUBOBJECT(HyprlandGeneralConfig, general)
    CONFIG_SUBOBJECT(HyprlandInputConfig, input)

public:
    explicit HyprlandConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_animations(new HyprlandAnimationsConfig(this))
        , m_autostartApps(new HyprlandAutostartConfig(this))
        , m_decoration(new HyprlandDecorationConfig(this))
        , m_general(new HyprlandGeneralConfig(this))
        , m_input(new HyprlandInputConfig(this)) {}
};

} // namespace caelestia::config
