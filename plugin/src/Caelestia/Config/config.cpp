#include "config.hpp"
#include "appearanceconfig.hpp"
#include "backgroundconfig.hpp"
#include "barconfig.hpp"
#include "borderconfig.hpp"
#include "configmigration.hpp"
#include "dashboardconfig.hpp"
#include "generalconfig.hpp"
#include "hyprlandconfig.hpp"
#include "interactionconfig.hpp"
#include "launcherconfig.hpp"
#include "lockconfig.hpp"
#include "monitorconfigmanager.hpp"
#include "nexusconfig.hpp"
#include "notifsconfig.hpp"
#include "optionalconfig.hpp"
#include "profileconfig.hpp"
#include "searchconfig.hpp"
#include "osdconfig.hpp"
#include "serviceconfig.hpp"
#include "sessionconfig.hpp"
#include "sidebarconfig.hpp"
#include "timeconfig.hpp"
#include "tokens.hpp"
#include "userpaths.hpp"
#include "utilitiesconfig.hpp"
#include "winfoconfig.hpp"
#include "windowsconfig.hpp"

#include <qqmlengine.h>
#include <qstandardpaths.h>

namespace caelestia::config {

namespace {

QString configDir() {
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QStringLiteral("/caelestia/");
}

} // namespace

GlobalConfig::GlobalConfig(QObject* parent)
    : RootConfig(parent)
    , m_appearance(new AppearanceConfig(this))
    , m_general(new GeneralConfig(this))
    , m_hyprland(new HyprlandConfig(this))
    , m_interactions(new InteractionConfig(this))
    , m_language(new LanguageConfig(this))
    , m_background(new BackgroundConfig(this))
    , m_bar(new BarConfig(this))
    , m_border(new BorderConfig(this))
    , m_dashboard(new DashboardConfig(this))
    , m_launcher(new LauncherConfig(this))
    , m_lock(new LockConfig(this))
    , m_nexus(new NexusConfig(this))
    , m_notifs(new NotifsConfig(this))
    , m_policies(new PolicyConfig(this))
    , m_ai(new AiConfig(this))
    , m_conflictKiller(new ConflictKillerConfig(this))
    , m_crosshair(new CrosshairConfig(this))
    , m_dock(new DockConfig(this))
    , m_light(new LightConfig(this))
    , m_musicRecognition(new MusicRecognitionConfig(this))
    , m_osk(new OskConfig(this))
    , m_overlay(new OverlayConfig(this))
    , m_overview(new OverviewConfig(this))
    , m_osd(new OsdConfig(this))
    , m_profile(new ProfileConfig(this))
    , m_regionSelector(new RegionSelectorConfig(this))
    , m_search(new SearchConfig(this))
    , m_services(new ServiceConfig(this))
    , m_session(new SessionConfig(this))
    , m_sidebar(new SidebarConfig(this))
    , m_sounds(new SoundsConfig(this))
    , m_time(new TimeConfig(this))
    , m_updates(new UpdatesConfig(this))
    , m_utilities(new UtilitiesConfig(this))
    , m_winfo(new WInfoConfig(this))
    , m_windows(new WindowsConfig(this))
    , m_hacks(new HacksConfig(this))
    , m_workSafety(new WorkSafetyConfig(this))
    , m_paths(new UserPaths(this)) {
    setupFileBackend(configDir() + QStringLiteral("shell.json"));
    setDefaults(defaults());
}

GlobalConfig::GlobalConfig(GlobalConfig* fallback, const QString& filePath, const QString& screen, QObject* parent)
    : RootConfig(parent)
    , m_appearance(new AppearanceConfig(this))
    , m_general(new GeneralConfig(this))
    , m_hyprland(new HyprlandConfig(this))
    , m_interactions(new InteractionConfig(this))
    , m_language(new LanguageConfig(this))
    , m_background(new BackgroundConfig(this))
    , m_bar(new BarConfig(this))
    , m_border(new BorderConfig(this))
    , m_dashboard(new DashboardConfig(this))
    , m_launcher(new LauncherConfig(this))
    , m_lock(new LockConfig(this))
    , m_nexus(new NexusConfig(this))
    , m_notifs(new NotifsConfig(this))
    , m_policies(new PolicyConfig(this))
    , m_ai(new AiConfig(this))
    , m_conflictKiller(new ConflictKillerConfig(this))
    , m_crosshair(new CrosshairConfig(this))
    , m_dock(new DockConfig(this))
    , m_light(new LightConfig(this))
    , m_musicRecognition(new MusicRecognitionConfig(this))
    , m_osk(new OskConfig(this))
    , m_overlay(new OverlayConfig(this))
    , m_overview(new OverviewConfig(this))
    , m_osd(new OsdConfig(this))
    , m_profile(new ProfileConfig(this))
    , m_regionSelector(new RegionSelectorConfig(this))
    , m_search(new SearchConfig(this))
    , m_services(new ServiceConfig(this))
    , m_session(new SessionConfig(this))
    , m_sidebar(new SidebarConfig(this))
    , m_sounds(new SoundsConfig(this))
    , m_time(new TimeConfig(this))
    , m_updates(new UpdatesConfig(this))
    , m_utilities(new UtilitiesConfig(this))
    , m_winfo(new WInfoConfig(this))
    , m_windows(new WindowsConfig(this))
    , m_hacks(new HacksConfig(this))
    , m_workSafety(new WorkSafetyConfig(this))
    , m_paths(new UserPaths(this)) {
    if (fallback)
        syncFromGlobal(fallback);
    if (!filePath.isEmpty())
        setupFileBackend(filePath, screen);

    // Bind appearance computed properties to token base values
    bindAppearanceTokens();
}

GlobalConfig* GlobalConfig::instance() {
    static GlobalConfig instance;
    instance.bindAppearanceTokens();
    return &instance;
}

GlobalConfig* GlobalConfig::defaults() {
    if (!m_defaults)
        m_defaults = new GlobalConfig(nullptr, QString(), QString(), this);
    return m_defaults;
}

void GlobalConfig::bindAppearanceTokens() {
    if (m_tokensBound)
        return;

    qCDebug(lcConfig) << "GlobalConfig::bindAppearanceTokens: binding appearance to token values";
    auto* const tokenAppearance = TokenConfig::instance()->appearance();
    m_appearance->rounding()->bindTokens(tokenAppearance->rounding());
    m_appearance->spacing()->bindTokens(tokenAppearance->spacing());
    m_appearance->padding()->bindTokens(tokenAppearance->padding());
    m_appearance->anim()->durations()->bindTokens(tokenAppearance->animDurations());
    m_tokensBound = true;
}

int GlobalConfig::currentConfigVersion() const {
    return CurrentGlobalConfigVersion;
}

QString GlobalConfig::migrateConfig(QJsonObject& json, int fromVersion) const {
    const auto result = migrateGlobalConfig(std::move(json), fromVersion);
    if (!result.error.isEmpty())
        return result.error;
    json = result.config;
    return {};
}

GlobalConfig* GlobalConfig::forScreen(const QString& screen) {
    return MonitorConfigManager::instance()->configForScreen(screen);
}

GlobalConfig* GlobalConfig::create(QQmlEngine*, QJSEngine*) {
    QQmlEngine::setObjectOwnership(instance(), QQmlEngine::CppOwnership);
    return instance();
}

} // namespace caelestia::config
