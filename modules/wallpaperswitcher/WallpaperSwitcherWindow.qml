pragma Singleton

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.wallpaperswitcher

// A standalone floating window for switching the wallpaper - separate from the
// main Nexus settings window, so it can be toggled on its own with a keybind.
Singleton {
    id: root

    property FloatingWindow current: null

    function open(targetScreen: ShellScreen): void {
        const screen = targetScreen ?? ShellState.forActive()?.modelData ?? Quickshell.screens[0];
        if (!screen)
            return;

        if (current) {
            current.raise();
            return;
        }

        current = windowComp.createObject(dummy, {
            screen: screen
        });
    }

    function close(): void {
        current?.destroy();
    }

    function toggle(targetScreen: ShellScreen): void {
        if (current)
            close();
        else
            open(targetScreen);
    }

    QtObject {
        id: dummy
    }

    Component {
        id: windowComp

        FloatingWindow {
            id: win

            color: Colours.tPalette.m3surface
            surfaceFormat.opaque: false

            implicitWidth: content.implicitWidth
            implicitHeight: content.implicitHeight

            contentItem.Config.screen: screen.name
            contentItem.Tokens.screen: screen.name

            title: qsTr("Đổi hình nền")

            onVisibleChanged: {
                if (!visible)
                    destroy();
            }

            Component.onDestruction: {
                if (root.current === win)
                    root.current = null;
            }

            WallpaperSwitcher {
                id: content

                anchors.fill: parent
                targetScreen: win.screen
                onRequestClose: win.destroy()
            }

            Behavior on color {
                CAnim {}
            }
        }
    }
}
