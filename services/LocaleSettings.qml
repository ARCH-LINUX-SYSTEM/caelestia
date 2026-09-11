import QtQuick
import Quickshell
import Caelestia.Config

Scope {
    id: root

    readonly property string systemLanguage: {
        const locale = Quickshell.env("LC_ALL") || Quickshell.env("LC_MESSAGES") || Quickshell.env("LANG");
        return locale ? locale.split(".")[0] : Qt.locale().name;
    }

    function applyLanguage(): void {
        const configured = GlobalConfig.language.ui.trim();
        Qt.uiLanguage = configured && configured !== "auto" ? configured : systemLanguage;
    }

    Component.onCompleted: applyLanguage()

    Connections {
        function onUiChanged(): void {
            root.applyLanguage();
        }

        target: GlobalConfig.language
    }
}
