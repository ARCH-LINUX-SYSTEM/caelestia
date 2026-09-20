pragma ComponentBehavior: Bound

import Quickshell
import Caelestia.Config
import qs.services

Variants {
    model: GlobalConfig.dock.enabled ? Screens.screens : []

    DockWindow {
        required property ShellScreen modelData

        screen: modelData
    }
}
