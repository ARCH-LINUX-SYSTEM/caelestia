#include "configmigration.hpp"

#include <cmath>
#include <functional>
#include <limits>
#include <qjsonarray.h>
#include <qjsonvalue.h>
#include <qprocess.h>
#include <qregularexpression.h>

namespace caelestia::config {

namespace {

QJsonObject childObject(const QJsonObject& parent, const QString& key) {
    const auto value = parent.value(key);
    return value.isObject() ? value.toObject() : QJsonObject();
}

void insertIfMissing(QJsonObject& object, const QString& key, const QJsonValue& value) {
    if (!object.contains(key) && !value.isUndefined())
        object.insert(key, value);
}

QStringList pathParts(const QString& path) {
    return path.split(QLatin1Char('.'), Qt::SkipEmptyParts);
}

QJsonValue valueAtPath(const QJsonObject& object, const QString& path) {
    const auto parts = pathParts(path);
    if (parts.isEmpty())
        return QJsonValue(QJsonValue::Undefined);

    auto current = object;
    for (auto index = 0; index < parts.size(); ++index) {
        const auto value = current.value(parts.at(index));
        if (index == parts.size() - 1)
            return value;
        if (!value.isObject())
            return QJsonValue(QJsonValue::Undefined);
        current = value.toObject();
    }
    return QJsonValue(QJsonValue::Undefined);
}

bool containsPath(const QJsonObject& object, const QString& path) {
    return !valueAtPath(object, path).isUndefined();
}

void setPath(QJsonObject& object, const QStringList& parts, int index, const QJsonValue& value) {
    if (index >= parts.size())
        return;
    if (index == parts.size() - 1) {
        object.insert(parts.at(index), value);
        return;
    }

    auto child = childObject(object, parts.at(index));
    setPath(child, parts, index + 1, value);
    object.insert(parts.at(index), child);
}

void setPath(QJsonObject& object, const QString& path, const QJsonValue& value) {
    const auto parts = pathParts(path);
    if (!parts.isEmpty())
        setPath(object, parts, 0, value);
}

bool removePath(QJsonObject& object, const QStringList& parts, int index) {
    if (index >= parts.size() || !object.contains(parts.at(index)))
        return false;
    if (index == parts.size() - 1) {
        object.remove(parts.at(index));
        return true;
    }

    const auto childValue = object.value(parts.at(index));
    if (!childValue.isObject())
        return false;
    auto child = childValue.toObject();
    if (!removePath(child, parts, index + 1))
        return false;
    if (child.isEmpty())
        object.remove(parts.at(index));
    else
        object.insert(parts.at(index), child);
    return true;
}

void removePath(QJsonObject& object, const QString& path) {
    const auto parts = pathParts(path);
    if (!parts.isEmpty())
        removePath(object, parts, 0);
}

QJsonObject mergeMissing(QJsonObject target, const QJsonObject& source) {
    for (auto it = source.begin(); it != source.end(); ++it) {
        if (!target.contains(it.key())) {
            target.insert(it.key(), it.value());
        } else if (target.value(it.key()).isObject() && it.value().isObject()) {
            target.insert(
                it.key(), mergeMissing(target.value(it.key()).toObject(), it.value().toObject()));
        }
    }
    return target;
}

using ValueTransform = std::function<QJsonValue(const QJsonValue&)>;

void migratePath(QJsonObject& config, const QString& sourcePath, const QString& targetPath,
    const ValueTransform& transform = {}) {
    const auto source = valueAtPath(config, sourcePath);
    if (source.isUndefined())
        return;

    if (!containsPath(config, targetPath)) {
        const auto transformed = transform ? transform(source) : source;
        if (transformed.isUndefined())
            return;
        setPath(config, targetPath, transformed);
    }
    if (sourcePath != targetPath)
        removePath(config, sourcePath);
}

void copyPathIfMissing(QJsonObject& config, const QString& sourcePath, const QString& targetPath) {
    const auto source = valueAtPath(config, sourcePath);
    if (!source.isUndefined() && !containsPath(config, targetPath))
        setPath(config, targetPath, source);
}

void moveObjectMerged(QJsonObject& config, const QString& sourcePath, const QString& targetPath) {
    const auto source = valueAtPath(config, sourcePath);
    if (!source.isObject())
        return;

    auto target = valueAtPath(config, targetPath);
    const auto merged =
        mergeMissing(target.isObject() ? target.toObject() : QJsonObject(), source.toObject());
    setPath(config, targetPath, merged);
    removePath(config, sourcePath);
}

QJsonValue percentageToRatio(const QJsonValue& value) {
    const auto number = value.toDouble(std::numeric_limits<double>::quiet_NaN());
    if (!value.isDouble() || !std::isfinite(number))
        return QJsonValue(QJsonValue::Undefined);
    return number / 100.0;
}

QJsonValue transparencyToOpacity(const QJsonValue& value) {
    const auto number = value.toDouble(std::numeric_limits<double>::quiet_NaN());
    if (!value.isDouble() || !std::isfinite(number))
        return QJsonValue(QJsonValue::Undefined);
    return 1.0 - number;
}

QJsonValue commandToArgv(const QJsonValue& value) {
    if (value.isArray())
        return value;
    if (!value.isString())
        return QJsonValue(QJsonValue::Undefined);

    QJsonArray command;
    for (const auto& part : QProcess::splitCommand(value.toString()))
        command.append(part);
    return command;
}

QJsonValue millisecondsToMinutes(const QJsonValue& value) {
    const auto number = value.toDouble(std::numeric_limits<double>::quiet_NaN());
    if (!value.isDouble() || !std::isfinite(number))
        return QJsonValue(QJsonValue::Undefined);
    return std::round(number / 60000.0);
}

QJsonValue quickTogglesToCaelestia(const QJsonValue& value) {
    if (!value.isArray())
        return QJsonValue(QJsonValue::Undefined);

    QJsonArray toggles;
    for (const auto& entryValue : value.toArray()) {
        if (!entryValue.isObject())
            continue;
        const auto source = entryValue.toObject();
        auto id = source.value(QStringLiteral("type")).toString();
        if (id.isEmpty())
            id = source.value(QStringLiteral("id")).toString();
        if (id == QStringLiteral("network"))
            id = QStringLiteral("wifi");
        if (id.isEmpty())
            continue;

        auto target = source;
        target.remove(QStringLiteral("type"));
        target.insert(QStringLiteral("id"), id);
        if (!target.contains(QStringLiteral("enabled")))
            target.insert(QStringLiteral("enabled"), true);
        toggles.append(target);
    }
    return toggles;
}

void migrateV0ToV1(QJsonObject& config) {
    // These aliases cover earlier/manual attempts to place end4-shaped values
    // directly in Caelestia's shell.json. Existing canonical Caelestia keys win.
    auto services = childObject(config, QStringLiteral("services"));
    auto audio = childObject(config, QStringLiteral("audio"));
    const auto protection = childObject(audio, QStringLiteral("protection"));
    if (!protection.isEmpty()) {
        auto target = childObject(services, QStringLiteral("audioProtection"));
        insertIfMissing(target, QStringLiteral("enabled"), protection.value(QStringLiteral("enable")));
        insertIfMissing(
            target, QStringLiteral("maxIncrease"), percentageToRatio(protection.value(QStringLiteral("maxAllowedIncrease"))));
        if (!target.isEmpty())
            services.insert(QStringLiteral("audioProtection"), target);
        insertIfMissing(
            services, QStringLiteral("maxVolume"), percentageToRatio(protection.value(QStringLiteral("maxAllowed"))));
        audio.remove(QStringLiteral("protection"));
        if (audio.isEmpty())
            config.remove(QStringLiteral("audio"));
        else
            config.insert(QStringLiteral("audio"), audio);
    }

    if (!services.isEmpty())
        config.insert(QStringLiteral("services"), services);

    auto general = childObject(config, QStringLiteral("general"));
    auto battery = childObject(config, QStringLiteral("battery"));
    if (!battery.isEmpty()) {
        auto target = childObject(general, QStringLiteral("battery"));
        insertIfMissing(
            target, QStringLiteral("autoHibernate"), battery.value(QStringLiteral("automaticSuspend")));
        insertIfMissing(target, QStringLiteral("criticalLevel"), battery.value(QStringLiteral("suspend")));
        if (!target.isEmpty())
            general.insert(QStringLiteral("battery"), target);
        battery.remove(QStringLiteral("automaticSuspend"));
        battery.remove(QStringLiteral("suspend"));
        if (battery.isEmpty())
            config.remove(QStringLiteral("battery"));
        else
            config.insert(QStringLiteral("battery"), battery);
    }

    auto custom = childObject(config, QStringLiteral("custom"));
    if (!custom.isEmpty()) {
        insertIfMissing(general, QStringLiteral("logo"), custom.value(QStringLiteral("distroIcon")));

        auto lock = childObject(config, QStringLiteral("lock"));
        insertIfMissing(lock, QStringLiteral("recolourLogo"), custom.value(QStringLiteral("colorizeIcon")));
        if (!lock.isEmpty())
            config.insert(QStringLiteral("lock"), lock);
        custom.remove(QStringLiteral("distroIcon"));
        custom.remove(QStringLiteral("colorizeIcon"));
        if (custom.isEmpty())
            config.remove(QStringLiteral("custom"));
        else
            config.insert(QStringLiteral("custom"), custom);
    }

    if (!general.isEmpty())
        config.insert(QStringLiteral("general"), general);

    auto notifications = childObject(config, QStringLiteral("notifications"));
    if (!notifications.isEmpty()) {
        auto notifs = childObject(config, QStringLiteral("notifs"));
        insertIfMissing(
            notifs, QStringLiteral("defaultExpireTimeout"), notifications.value(QStringLiteral("timeout")));
        if (!notifs.isEmpty())
            config.insert(QStringLiteral("notifs"), notifs);
        notifications.remove(QStringLiteral("timeout"));
        if (notifications.isEmpty())
            config.remove(QStringLiteral("notifications"));
        else
            config.insert(QStringLiteral("notifications"), notifications);
    }

    auto osd = childObject(config, QStringLiteral("osd"));
    if (osd.contains(QStringLiteral("timeout"))) {
        insertIfMissing(osd, QStringLiteral("hideDelay"), osd.value(QStringLiteral("timeout")));
        osd.remove(QStringLiteral("timeout"));
        config.insert(QStringLiteral("osd"), osd);
    }

    auto launcher = childObject(config, QStringLiteral("launcher"));
    if (launcher.contains(QStringLiteral("pinnedApps"))) {
        insertIfMissing(
            launcher, QStringLiteral("favouriteApps"), launcher.value(QStringLiteral("pinnedApps")));
        launcher.remove(QStringLiteral("pinnedApps"));
        config.insert(QStringLiteral("launcher"), launcher);
    }

    auto tray = childObject(config, QStringLiteral("tray"));
    if (!tray.isEmpty()) {
        auto bar = childObject(config, QStringLiteral("bar"));
        auto target = childObject(bar, QStringLiteral("tray"));
        insertIfMissing(target, QStringLiteral("recolour"), tray.value(QStringLiteral("monochromeIcons")));
        if (!target.isEmpty())
            bar.insert(QStringLiteral("tray"), target);
        if (!bar.isEmpty())
            config.insert(QStringLiteral("bar"), bar);
        tray.remove(QStringLiteral("monochromeIcons"));
        if (tray.isEmpty())
            config.remove(QStringLiteral("tray"));
        else
            config.insert(QStringLiteral("tray"), tray);
    }
}

void migrateV1ToV2(QJsonObject& config) {
    auto bar = childObject(config, QStringLiteral("bar"));
    const auto entriesValue = bar.value(QStringLiteral("entries"));
    if (!entriesValue.isArray())
        return;

    auto entries = entriesValue.toArray();
    auto containsEntry = [&entries](const QString& id) {
        for (const auto& entryValue : entries) {
            if (entryValue.isObject()
                && entryValue.toObject().value(QStringLiteral("id")).toString() == id) {
                return true;
            }
        }
        return false;
    };
    auto appendOptional = [&entries, &containsEntry](const QString& id) {
        if (!containsEntry(id)) {
            entries.append(QJsonObject{
                { QStringLiteral("id"), id },
                { QStringLiteral("enabled"), false },
            });
        }
    };

    appendOptional(QStringLiteral("resources"));
    appendOptional(QStringLiteral("weather"));
    bar.insert(QStringLiteral("entries"), entries);
    config.insert(QStringLiteral("bar"), bar);
}

void migrateV2ToV3(QJsonObject& config) {
    const auto migrate = [&config](const char* source, const char* target,
                             const ValueTransform& transform = {}) {
        migratePath(config, QString::fromLatin1(source), QString::fromLatin1(target), transform);
    };

    // Appearance roles are merged into Caelestia's existing font hierarchy.
    copyPathIfMissing(config, QStringLiteral("appearance.fonts.main"),
        QStringLiteral("appearance.font.body.family"));
    copyPathIfMissing(config, QStringLiteral("appearance.fonts.main"),
        QStringLiteral("appearance.font.label.family"));
    copyPathIfMissing(config, QStringLiteral("appearance.fonts.title"),
        QStringLiteral("appearance.font.title.family"));
    copyPathIfMissing(config, QStringLiteral("appearance.fonts.title"),
        QStringLiteral("appearance.font.headline.family"));
    migrate("appearance.fonts.numbers", "appearance.font.numbers");
    migrate("appearance.fonts.iconNerd", "appearance.font.workspaces");
    migrate("appearance.fonts.monospace", "appearance.font.mono.family");
    migrate("appearance.fonts.reading", "appearance.font.reading");
    migrate("appearance.fonts.expressive", "appearance.font.expressive");
    removePath(config, QStringLiteral("appearance.fonts.main"));
    removePath(config, QStringLiteral("appearance.fonts.title"));

    migrate("appearance.transparency.enable", "appearance.transparency.enabled");
    migrate("appearance.transparency.backgroundTransparency", "appearance.transparency.base",
        transparencyToOpacity);
    migrate("appearance.transparency.contentTransparency", "appearance.transparency.layers",
        transparencyToOpacity);

    const auto accent = valueAtPath(config, QStringLiteral("appearance.palette.accentColor"));
    if (accent.isString()) {
        const auto colour = accent.toString().trimmed();
        const QRegularExpression bareHex(QStringLiteral("^[0-9A-Fa-f]{6}(?:[0-9A-Fa-f]{2})?$"));
        if (bareHex.match(colour).hasMatch())
            setPath(config, QStringLiteral("appearance.palette.accentColor"), QLatin1Char('#') + colour);
    }

    // Keep support for end4-shaped values added after an earlier Caelestia migration.
    migrate("audio.protection.enable", "services.audioProtection.enabled");
    migrate("audio.protection.maxAllowedIncrease", "services.audioProtection.maxIncrease",
        percentageToRatio);
    migrate("audio.protection.maxAllowed", "services.maxVolume", percentageToRatio);

    migrate("hyprland.animations.enable", "hyprland.animations.enabled");
    migrate("hyprland.autostartApps.enable", "hyprland.autostartApps.enabled");

    const auto appNames = { "bluetooth", "changePassword", "network", "manageUser",
        "networkEthernet", "taskManager", "terminal", "update" };
    for (const auto* name : appNames) {
        migratePath(config, QStringLiteral("apps.") + QString::fromLatin1(name),
            QStringLiteral("general.apps.") + QString::fromLatin1(name), commandToArgv);
    }
    migrate("apps.volumeMixer", "general.apps.audio", commandToArgv);

    // Clock and visualiser are existing Caelestia modules, so merge into them.
    moveObjectMerged(config, QStringLiteral("background.widgets.clock"),
        QStringLiteral("background.desktopClock"));
    moveObjectMerged(config, QStringLiteral("background.widgets.visualizer"),
        QStringLiteral("background.visualiser"));
    migrate("background.desktopClock.enable", "background.desktopClock.enabled");
    migrate("background.desktopClock.quote.enable", "background.desktopClock.quote.enabled");
    migrate("background.visualiser.enable", "background.visualiser.enabled");
    for (const auto* widget :
        { "weather", "calendar", "worldClock", "userCard", "images", "customImage",
            "resources", "media" }) {
        const auto base = QStringLiteral("background.widgets.") + QString::fromLatin1(widget);
        migratePath(config, base + QStringLiteral(".enable"), base + QStringLiteral(".enabled"));
    }

    if (!containsPath(config, QStringLiteral("general.battery.warnLevels"))) {
        QJsonArray levels;
        const auto low = valueAtPath(config, QStringLiteral("battery.low"));
        const auto critical = valueAtPath(config, QStringLiteral("battery.critical"));
        if (low.isDouble()) {
            levels.append(QJsonObject{
                { QStringLiteral("level"), low },
                { QStringLiteral("title"), QStringLiteral("Low battery") },
                { QStringLiteral("message"), QStringLiteral("You might want to plug in a charger") },
                { QStringLiteral("icon"), QStringLiteral("battery_android_frame_2") },
            });
        }
        if (critical.isDouble()) {
            levels.append(QJsonObject{
                { QStringLiteral("level"), critical },
                { QStringLiteral("title"), QStringLiteral("Critical battery level") },
                { QStringLiteral("message"), QStringLiteral("Plug in the charger now") },
                { QStringLiteral("icon"), QStringLiteral("battery_android_alert") },
                { QStringLiteral("critical"), true },
            });
        }
        if (!levels.isEmpty())
            setPath(config, QStringLiteral("general.battery.warnLevels"), levels);
    }
    removePath(config, QStringLiteral("battery.low"));
    removePath(config, QStringLiteral("battery.critical"));
    migrate("battery.full", "general.battery.fullLevel");
    migrate("battery.automaticSuspend", "general.battery.autoHibernate");
    migrate("battery.suspend", "general.battery.criticalLevel");

    migrate("calendar.locale", "services.calendarLocale");
    migrate("media.filterDuplicatePlayers", "services.filterDuplicatePlayers");
    migrate("networking.userAgent", "services.networkUserAgent");
    migrate("notifications.timeout", "notifs.defaultExpireTimeout");
    migrate("osd.timeout", "osd.hideDelay");
    migrate("resources.updateInterval", "dashboard.resourceUpdateInterval");
    migrate("resources.historyLength", "dashboard.resourceHistoryLength");
    migrate("launcher.pinnedApps", "launcher.favouriteApps");

    migrate("dock.enable", "dock.enabled");
    migrate("interactions.deadPixelWorkaround.enable",
        "interactions.deadPixelWorkaround.enabled");
    migrate("light.antiFlashbang.enable", "light.antiFlashbang.enabled");
    migrate("overview.enable", "overview.enabled");

    migrate("tray.monochromeIcons", "bar.tray.recolour");
    migrate("tray.showItemId", "bar.tray.showItemId");
    migrate("tray.invertPinnedItems", "bar.tray.invertPinnedItems");
    migrate("tray.pinnedItems", "bar.tray.pinnedItems");
    migrate("tray.filterPassive", "bar.tray.filterPassive");

    migrate("search.prefix.action", "launcher.actionPrefix");
    migrate("search.prefix.app", "launcher.appPrefix");

    migrate("sidebar.quickToggles.style", "utilities.quickToggleStyle");
    migrate("sidebar.quickToggles.android.columns", "utilities.quickToggleColumns");
    migrate("sidebar.quickToggles.android.toggles", "utilities.quickToggles",
        quickTogglesToCaelestia);

    migrate("custom.distroIcon", "general.logo");
    migrate("custom.colorizeIcon", "lock.recolourLogo");
    migrate("screenRecord.savePath", "paths.screenRecordDir");
    migrate("screenSnip.savePath", "paths.screenSnipDir");

    migrate("wallpaperSelector.useSystemFileDialog", "nexus.useSystemFileDialog");
    migrate("wallpaperSelector.showBlurBackground", "nexus.showWallpaperBlurBackground");
    migrate("wallpaperSelector.showHomePath", "nexus.showWallpaperHomePath");
    migrate("wallpaperSelector.userPath", "nexus.wallpaperUserPath");
    migrate("wallpaperSelector.showSearchbar", "nexus.showWallpaperSearch");
    migrate("wallpaperSelector.columns", "nexus.wallpapersPerRow");
    migrate(
        "wallpaperSelector.closeAfterSelection", "nexus.closeAfterWallpaperSelection");
    migrate("wallpaperSelector.changeInterval", "nexus.wallpaperChangeInterval",
        millisecondsToMinutes);
}

} // namespace

ConfigMigrationResult migrateGlobalConfig(QJsonObject config, int fromVersion) {
    if (fromVersion < 0)
        return { std::move(config), QStringLiteral("source version must be non-negative") };
    if (fromVersion > CurrentGlobalConfigVersion) {
        return { std::move(config),
            QStringLiteral("source version %1 is newer than %2").arg(fromVersion).arg(CurrentGlobalConfigVersion) };
    }

    for (auto version = fromVersion; version < CurrentGlobalConfigVersion; ++version) {
        switch (version) {
        case 0:
            migrateV0ToV1(config);
            break;
        case 1:
            migrateV1ToV2(config);
            break;
        case 2:
            migrateV2ToV3(config);
            break;
        default:
            return { std::move(config), QStringLiteral("no migration registered for version %1").arg(version) };
        }
    }

    return { std::move(config), {} };
}

} // namespace caelestia::config
