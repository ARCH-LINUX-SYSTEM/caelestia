#pragma once

#include "configobject.hpp"

#include <qstring.h>
#include <qstringlist.h>
#include <qvariant.h>

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

class GeneralApps : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(QStringList, terminal, { u"foot"_s })
    CONFIG_GLOBAL_PROPERTY(QStringList, audio, { u"pavucontrol"_s })
    CONFIG_GLOBAL_PROPERTY(QStringList, playback, { u"mpv"_s })
    CONFIG_GLOBAL_PROPERTY(QStringList, explorer, { u"thunar"_s })
    CONFIG_GLOBAL_PROPERTY(QStringList, bluetooth, { u"kcmshell6"_s, u"kcm_bluetooth"_s })
    CONFIG_GLOBAL_PROPERTY(
        QStringList, changePassword, { u"kitty"_s, u"-1"_s, u"--hold=yes"_s, u"fish"_s, u"-i"_s, u"-c"_s, u"passwd"_s })
    CONFIG_GLOBAL_PROPERTY(QStringList, network, { u"kcmshell6"_s, u"kcm_networkmanagement"_s })
    CONFIG_GLOBAL_PROPERTY(QStringList, manageUser, { u"kcmshell6"_s, u"kcm_users"_s })
    CONFIG_GLOBAL_PROPERTY(QStringList, networkEthernet, { u"kcmshell6"_s, u"kcm_networkmanagement"_s })
    CONFIG_GLOBAL_PROPERTY(
        QStringList, taskManager, { u"plasma-systemmonitor"_s, u"--page-name"_s, u"Processes"_s })
    CONFIG_GLOBAL_PROPERTY(QStringList, update,
        { u"kitty"_s, u"-1"_s, u"--hold=yes"_s, u"fish"_s, u"-i"_s, u"-c"_s,
            u"pkexec pacman -Syu"_s })

public:
    explicit GeneralApps(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class GeneralIdle : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(bool, lockBeforeSleep, true)
    CONFIG_GLOBAL_PROPERTY(bool, inhibitWhenAudio, true)
    CONFIG_GLOBAL_PROPERTY(bool, inhibitWhenCharging, false)
    CONFIG_GLOBAL_PROPERTY(QVariantList, timeouts,
        {
            vmap({
                { u"timeout"_s, 180 },
                { u"idleAction"_s, u"lock"_s },
            }),
            vmap({
                { u"timeout"_s, 300 },
                { u"idleAction"_s, u"dpms off"_s },
                { u"returnAction"_s, u"dpms on"_s },
            }),
            vmap({
                { u"timeout"_s, 600 },
                { u"idleAction"_s, QStringList{ u"suspendThenHibernate"_s } },
            }),
        })

public:
    explicit GeneralIdle(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class GeneralBattery : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(QVariantList, warnLevels,
        {
            vmap({
                { u"level"_s, 20 },
                { u"title"_s, u"Low battery"_s },
                { u"message"_s, u"You might want to plug in a charger"_s },
                { u"icon"_s, u"battery_android_frame_2"_s },
            }),
            vmap({
                { u"level"_s, 10 },
                { u"title"_s, u"Did you see the previous message?"_s },
                { u"message"_s, u"You should probably plug in a charger <b>now</b>"_s },
                { u"icon"_s, u"battery_android_frame_1"_s },
            }),
            vmap({
                { u"level"_s, 5 },
                { u"title"_s, u"Critical battery level"_s },
                { u"message"_s, u"PLUG THE CHARGER RIGHT NOW!!"_s },
                { u"icon"_s, u"battery_android_alert"_s },
                { u"critical"_s, true },
            }),
        })
    CONFIG_GLOBAL_PROPERTY(int, criticalLevel, 3)
    CONFIG_GLOBAL_PROPERTY(bool, autoHibernate, true)
    CONFIG_GLOBAL_PROPERTY(int, hibernateDelay, 5)
    CONFIG_GLOBAL_PROPERTY(int, fullLevel, 101)

public:
    explicit GeneralBattery(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addRangeConstraint(QStringLiteral("criticalLevel"), 0, 100);
        addRangeConstraint(QStringLiteral("hibernateDelay"), 0, 3600);
        addRangeConstraint(QStringLiteral("fullLevel"), 0, 101);
        addValidator(QStringLiteral("warnLevels"), [](const QVariant& value) {
            for (const auto& entry : value.toList()) {
                const auto level = entry.toMap();
                if (level.isEmpty())
                    return QStringLiteral("must contain only warning objects");
                bool ok = false;
                const auto percentage = level.value(QStringLiteral("level")).toDouble(&ok);
                if (!ok || percentage < 0 || percentage > 100)
                    return QStringLiteral("each warning level must be between 0 and 100");
            }
            return QString();
        });
    }
};

class GeneralConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(QString, logo)
    CONFIG_PROPERTY(bool, showOverFullscreen, false)
    CONFIG_PROPERTY(qreal, mediaGifSpeedAdjustment, 300)
    CONFIG_PROPERTY(qreal, sessionGifSpeed, 0.7)
    CONFIG_SUBOBJECT(GeneralApps, apps)
    CONFIG_SUBOBJECT(GeneralIdle, idle)
    CONFIG_SUBOBJECT(GeneralBattery, battery)

public:
    explicit GeneralConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_apps(new GeneralApps(this))
        , m_idle(new GeneralIdle(this))
        , m_battery(new GeneralBattery(this)) {
        addRangeConstraint(QStringLiteral("mediaGifSpeedAdjustment"), 0, 10000);
        addRangeConstraint(QStringLiteral("sessionGifSpeed"), 0.01, 10);
    }
};

} // namespace caelestia::config
