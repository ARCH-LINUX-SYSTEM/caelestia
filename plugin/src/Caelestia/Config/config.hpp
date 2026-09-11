#pragma once

#include "rootconfig.hpp"

#include <qqmlengine.h>

namespace caelestia::config {

class AppearanceConfig;
class BackgroundConfig;
class BarConfig;
class BorderConfig;
class DashboardConfig;
class GeneralConfig;
class HyprlandConfig;
class InteractionConfig;
class LanguageConfig;
class LauncherConfig;
class LockConfig;
class NexusConfig;
class NotifsConfig;
class OskConfig;
class OverlayConfig;
class OverviewConfig;
class PolicyConfig;
class ProfileConfig;
class RegionSelectorConfig;
class SearchConfig;
class AiConfig;
class ConflictKillerConfig;
class CrosshairConfig;
class DockConfig;
class HacksConfig;
class LightConfig;
class MusicRecognitionConfig;
class OsdConfig;
class ServiceConfig;
class SessionConfig;
class SidebarConfig;
class SoundsConfig;
class TimeConfig;
class UpdatesConfig;
class UserPaths;
class UtilitiesConfig;
class WInfoConfig;
class WorkSafetyConfig;
class WindowsConfig;

class GlobalConfig : public RootConfig {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_MOC_INCLUDE("appearanceconfig.hpp")
    Q_MOC_INCLUDE("backgroundconfig.hpp")
    Q_MOC_INCLUDE("barconfig.hpp")
    Q_MOC_INCLUDE("borderconfig.hpp")
    Q_MOC_INCLUDE("dashboardconfig.hpp")
    Q_MOC_INCLUDE("generalconfig.hpp")
    Q_MOC_INCLUDE("hyprlandconfig.hpp")
    Q_MOC_INCLUDE("interactionconfig.hpp")
    Q_MOC_INCLUDE("launcherconfig.hpp")
    Q_MOC_INCLUDE("lockconfig.hpp")
    Q_MOC_INCLUDE("nexusconfig.hpp")
    Q_MOC_INCLUDE("notifsconfig.hpp")
    Q_MOC_INCLUDE("optionalconfig.hpp")
    Q_MOC_INCLUDE("profileconfig.hpp")
    Q_MOC_INCLUDE("searchconfig.hpp")
    Q_MOC_INCLUDE("osdconfig.hpp")
    Q_MOC_INCLUDE("serviceconfig.hpp")
    Q_MOC_INCLUDE("sessionconfig.hpp")
    Q_MOC_INCLUDE("sidebarconfig.hpp")
    Q_MOC_INCLUDE("timeconfig.hpp")
    Q_MOC_INCLUDE("userpaths.hpp")
    Q_MOC_INCLUDE("utilitiesconfig.hpp")
    Q_MOC_INCLUDE("winfoconfig.hpp")
    Q_MOC_INCLUDE("windowsconfig.hpp")

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_SUBOBJECT(AppearanceConfig, appearance)
    CONFIG_SUBOBJECT(GeneralConfig, general)
    CONFIG_SUBOBJECT(HyprlandConfig, hyprland)
    CONFIG_SUBOBJECT(InteractionConfig, interactions)
    CONFIG_SUBOBJECT(LanguageConfig, language)
    CONFIG_SUBOBJECT(BackgroundConfig, background)
    CONFIG_SUBOBJECT(BarConfig, bar)
    CONFIG_SUBOBJECT(BorderConfig, border)
    CONFIG_SUBOBJECT(DashboardConfig, dashboard)
    CONFIG_SUBOBJECT(LauncherConfig, launcher)
    CONFIG_SUBOBJECT(LockConfig, lock)
    CONFIG_SUBOBJECT(NexusConfig, nexus)
    CONFIG_SUBOBJECT(NotifsConfig, notifs)
    CONFIG_SUBOBJECT(PolicyConfig, policies)
    CONFIG_SUBOBJECT(AiConfig, ai)
    CONFIG_SUBOBJECT(ConflictKillerConfig, conflictKiller)
    CONFIG_SUBOBJECT(CrosshairConfig, crosshair)
    CONFIG_SUBOBJECT(DockConfig, dock)
    CONFIG_SUBOBJECT(LightConfig, light)
    CONFIG_SUBOBJECT(MusicRecognitionConfig, musicRecognition)
    CONFIG_SUBOBJECT(OskConfig, osk)
    CONFIG_SUBOBJECT(OverlayConfig, overlay)
    CONFIG_SUBOBJECT(OverviewConfig, overview)
    CONFIG_SUBOBJECT(OsdConfig, osd)
    CONFIG_SUBOBJECT(ProfileConfig, profile)
    CONFIG_SUBOBJECT(RegionSelectorConfig, regionSelector)
    CONFIG_SUBOBJECT(SearchConfig, search)
    CONFIG_SUBOBJECT(ServiceConfig, services)
    CONFIG_SUBOBJECT(SessionConfig, session)
    CONFIG_SUBOBJECT(SidebarConfig, sidebar)
    CONFIG_SUBOBJECT(SoundsConfig, sounds)
    CONFIG_SUBOBJECT(TimeConfig, time)
    CONFIG_SUBOBJECT(UpdatesConfig, updates)
    CONFIG_SUBOBJECT(UtilitiesConfig, utilities)
    CONFIG_SUBOBJECT(WInfoConfig, winfo)
    CONFIG_SUBOBJECT(WindowsConfig, windows)
    CONFIG_SUBOBJECT(HacksConfig, hacks)
    CONFIG_SUBOBJECT(WorkSafetyConfig, workSafety)
    CONFIG_SUBOBJECT(UserPaths, paths)

public:
    static GlobalConfig* instance();
    [[nodiscard]] Q_INVOKABLE GlobalConfig* defaults();
    [[nodiscard]] Q_INVOKABLE static GlobalConfig* forScreen(const QString& screen);
    static GlobalConfig* create(QQmlEngine*, QJSEngine*);

    void bindAppearanceTokens();

protected:
    [[nodiscard]] int currentConfigVersion() const override;
    [[nodiscard]] QString migrateConfig(QJsonObject& json, int fromVersion) const override;

private:
    friend class MonitorConfigManager;
    explicit GlobalConfig(QObject* parent = nullptr);
    explicit GlobalConfig(
        GlobalConfig* fallback, const QString& filePath, const QString& screen = {}, QObject* parent = nullptr);

    GlobalConfig* m_defaults = nullptr;
    bool m_tokensBound = false;
};

} // namespace caelestia::config
