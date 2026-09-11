//@ pragma AppId io.github.conlongnhong.caelestia-shell-aw
//@ pragma Env QS_CRASHREPORT_URL=https://github.com/conlongnhong/caelestia-shell-aw/issues/new?template=crash.yml
//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
//@ pragma DefaultEnv QS_DROP_EXPENSIVE_FONTS=1
//@ pragma DefaultEnv QSG_RENDER_LOOP=threaded
//@ pragma DefaultEnv QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import "modules"
import "modules/drawers"
import "modules/background"
import "modules/areapicker"
import "modules/lock"
import "modules/windowswitcher"
import QtQuick
import Quickshell
import qs.services

ShellRoot {
    id: root

    settings.watchFiles: true
    readonly property bool hyprlandSettingsReady: HyprlandSettings.ready

    Binding {
        target: ShellState
        property: "shellRoot"
        value: root
    }

    Binding {
        target: ShellState
        property: "locked"
        value: lock.lock.locked
    }

    GSFLoader {}

    Background {}
    Drawers {}
    AreaPicker {}
    WindowSwitcher {}
    Lock {
        id: lock
    }

    ConfigToasts {}
    AppearanceSettings {}
    LocaleSettings {}
    Shortcuts {}
    BatteryMonitor {}
    IdleMonitors {
        lock: lock
    }
}
