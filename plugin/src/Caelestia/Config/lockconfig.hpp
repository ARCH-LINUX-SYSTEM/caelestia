#pragma once

#include "configobject.hpp"

namespace caelestia::config {

class LockBlurConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    // Safety gate: the existing Caelestia blur remains unchanged until explicitly managed.
    CONFIG_PROPERTY(bool, managed, false)
    CONFIG_PROPERTY(bool, enable, true)
    CONFIG_PROPERTY(qreal, radius, 100)
    CONFIG_PROPERTY(qreal, extraZoom, 1.1)
    CONFIG_PROPERTY(int, size, 20)

public:
    explicit LockBlurConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addRangeConstraint(QStringLiteral("radius"), 0, 100);
        addRangeConstraint(QStringLiteral("extraZoom"), 1, 2);
        addRangeConstraint(QStringLiteral("size"), 1, 128);
    }
};

class LockSecurityConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(bool, unlockKeyring, true)
    CONFIG_GLOBAL_PROPERTY(bool, requirePasswordToPower, false)

public:
    explicit LockSecurityConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class LockConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(bool, recolourLogo, true)
    CONFIG_GLOBAL_PROPERTY(bool, enableFprint, true)
    CONFIG_GLOBAL_PROPERTY(int, maxFprintTries, 3)
    CONFIG_GLOBAL_PROPERTY(bool, enableHowdy, true)
    CONFIG_GLOBAL_PROPERTY(int, maxHowdyTries, 3)
    CONFIG_GLOBAL_PROPERTY(bool, triggerHowdyOnWake, true)
    CONFIG_PROPERTY(bool, hideNotifs, false)
    CONFIG_GLOBAL_PROPERTY(bool, useHyprlock, false)
    CONFIG_GLOBAL_PROPERTY(bool, launchOnStartup, false)
    CONFIG_PROPERTY(bool, showWidgets, false)
    CONFIG_PROPERTY(bool, showMedia, true)
    CONFIG_SUBOBJECT(LockBlurConfig, blur)
    CONFIG_PROPERTY(bool, centerClock, true)
    CONFIG_PROPERTY(bool, showLockedText, true)
    CONFIG_SUBOBJECT(LockSecurityConfig, security)
    CONFIG_PROPERTY(bool, materialShapeChars, true)

public:
    explicit LockConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_blur(new LockBlurConfig(this))
        , m_security(new LockSecurityConfig(this)) {
        addRangeConstraint(QStringLiteral("maxFprintTries"), 1, 20);
        addRangeConstraint(QStringLiteral("maxHowdyTries"), 1, 20);
    }
};

} // namespace caelestia::config
