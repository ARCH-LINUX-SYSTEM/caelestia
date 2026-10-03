pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.misc
import qs.services
import qs.utils

// Top-centre "island" opened with SUPER+TAB: a workspace row and an app row.
Scope {
    id: root

    property var apps: []
    property int appIndex: -1
    property bool appsFocused: true
    property bool overlayVisible
    property bool presented
    property var spaces: []
    property int spaceIndex: -1
    property bool switching
    property string targetScreen: ""

    readonly property var selectedSpace: spaceIndex >= 0 && spaceIndex < spaces.length ? spaces[spaceIndex] : null

    function addressOf(client: var): string {
        const address = String(client?.address ?? "");
        return address.startsWith("0x") ? address.slice(2) : address;
    }

    function luaEscape(value: string): string {
        return value.replace(/\\/g, "\\\\").replace(/\"/g, "\\\"");
    }

    function isSwitchable(client: var): bool {
        if (!client || !addressOf(client))
            return false;
        const ipc = client.lastIpcObject ?? {};
        if (ipc.mapped !== true || ipc.hidden === true || ipc.noFocus === true)
            return false;
        if (String(client.workspace?.name ?? "").startsWith("special:"))
            return false;
        return String(client.title ?? "").trim().length > 0 || String(ipc.class ?? "").trim().length > 0;
    }

    // Workspaces 1..max(5, highest existing id), capped at 10, each with its window count.
    function buildSpaces(): var {
        const counts = new Map();
        let maxId = 5;
        for (const ws of Hypr.workspaces.values) {
            if (ws.id > 0)
                maxId = Math.max(maxId, ws.id);
        }
        for (const client of Hypr.toplevels.values) {
            if (isSwitchable(client)) {
                const id = client.workspace?.id ?? -1;
                counts.set(id, (counts.get(id) ?? 0) + 1);
            }
        }
        const list = [];
        for (let id = 1; id <= Math.min(10, maxId); ++id)
            list.push({
                id: id,
                count: counts.get(id) ?? 0
            });
        return list;
    }

    // Windows of one workspace, most recently focused first.
    function appsFor(workspaceId: int): var {
        return Hypr.toplevels.values.filter(c => isSwitchable(c) && c.workspace?.id === workspaceId).sort((a, b) => Number(a.lastIpcObject?.focusHistoryID ?? 1e9) - Number(b.lastIpcObject?.focusHistoryID ?? 1e9));
    }

    function refreshApps(): void {
        apps = selectedSpace ? appsFor(selectedSpace.id) : [];
        appIndex = apps.length > 0 ? Math.min(Math.max(appIndex, 0), apps.length - 1) : -1;
        if (apps.length === 0)
            appsFocused = false;
    }

    function selectSpace(index: int): void {
        if (index < 0 || index >= spaces.length)
            return;
        spaceIndex = index;
        appIndex = 0;
        refreshApps();
    }

    function screenForActiveMonitor(): string {
        const monitor = Hypr.focusedMonitor;
        const screen = Screens.screens.find(s => Hypr.monitorFor(s) === monitor);
        return screen?.name ?? Screens.screens[0]?.name ?? "";
    }

    // mode "workspace": SUPER+TAB cycles workspaces. mode "app": SUPER+SHIFT+TAB cycles apps.
    function start(mode: string): void {
        const appMode = mode === "app";
        if (switching) {
            appsFocused = appMode && apps.length > 0;
            step(1);
            return;
        }

        const list = buildSpaces();
        if (list.length === 0)
            return;

        const current = Hypr.focusedMonitor?.activeWorkspace?.id ?? Hypr.activeWsId;
        closeTimer.stop();
        spaces = list;
        targetScreen = screenForActiveMonitor();
        switching = true;
        overlayVisible = true;
        spaceIndex = Math.max(0, list.findIndex(s => s.id === current));
        apps = appsFor(list[spaceIndex].id);
        appsFocused = appMode && apps.length > 0;
        // Start on the next workspace / previously focused app, like Alt+Tab.
        appIndex = apps.length === 0 ? -1 : (apps.length > 1 && appMode ? 1 : 0);
        if (!appMode)
            spaceIndex = (spaceIndex + 1) % list.length;
        apps = appsFor(list[spaceIndex].id);
        Qt.callLater(() => {
            if (root.switching)
                root.presented = true;
        });
    }

    function step(direction: int): void {
        if (!switching)
            return;
        if (appsFocused && apps.length > 0)
            appIndex = (appIndex + direction + apps.length) % apps.length;
        else
            selectSpace((spaceIndex + direction + spaces.length) % spaces.length);
    }

    function toggleRow(): void {
        if (!appsFocused && apps.length > 0)
            appsFocused = true;
        else
            appsFocused = false;
    }

    function cancel(): void {
        finish(false);
    }

    function commit(): void {
        finish(true);
    }

    function finish(activateSelection: bool): void {
        if (!switching)
            return;

        const space = selectedSpace;
        const app = appsFocused && appIndex >= 0 ? apps[appIndex] : null;
        switching = false;
        presented = false;
        closeTimer.restart();

        if (!activateSelection)
            return;

        if (app) {
            const selector = `address:0x${addressOf(app)}`;
            Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({ window = "${luaEscape(selector)}" })` : `focuswindow ${selector}`);
        } else if (space) {
            Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({ workspace = ${space.id} })` : `workspace ${space.id}`);
        }
    }

    Timer {
        id: closeTimer

        interval: 220

        onTriggered: {
            root.overlayVisible = false;
            root.apps = [];
            root.spaces = [];
            root.appIndex = -1;
            root.spaceIndex = -1;
        }
    }

    Timer {
        id: refreshTimer

        interval: 60

        onTriggered: {
            if (!root.switching)
                return;
            const keepId = root.selectedSpace?.id;
            root.spaces = root.buildSpaces();
            root.spaceIndex = Math.max(0, root.spaces.findIndex(s => s.id === keepId));
            root.refreshApps();
        }
    }

    Connections {
        function onRawEvent(event: HyprlandEvent): void {
            if (root.switching && ["openwindow", "closewindow", "movewindowv2", "workspacev2"].includes(event.name))
                refreshTimer.restart();
        }

        target: Hyprland
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        description: qsTr("Chuyển không gian làm việc")
        // qmllint enable unresolved-type
        name: "spaceSwitcher"

        onPressed: root.start("workspace")
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        description: qsTr("Chuyển ứng dụng")
        // qmllint enable unresolved-type
        name: "appSwitcher"

        onPressed: root.start("app")
    }

    IpcHandler {
        function cancel(): void {
            root.cancel();
        }
        function commit(): void {
            root.commit();
        }
        function nextApp(): void {
            root.start("app");
        }
        function nextWorkspace(): void {
            root.start("workspace");
        }

        target: "spaceSwitcher"
    }

    Variants {
        model: Screens.screens

        StyledWindow {
            id: win

            required property ShellScreen modelData

            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: root.switching && visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            WlrLayershell.layer: WlrLayer.Overlay
            anchors.top: true
            color: "transparent"
            // Fixed-size surface; only the island itself takes input.
            implicitHeight: 360
            implicitWidth: Math.min(screen.width - 40, 960)
            mask: Region {
                item: island
            }
            name: "space-switcher"
            screen: modelData
            visible: root.overlayVisible && root.targetScreen === modelData.name

            onVisibleChanged: {
                if (visible)
                    keyHandler.forceActiveFocus();
            }

            Item {
                id: keyHandler

                anchors.fill: parent
                focus: root.switching && win.visible

                Keys.onPressed: event => {
                    const back = !root.appsFocused && ((event.modifiers & Qt.ShiftModifier) || event.key === Qt.Key_Backtab);
                    if (event.key === Qt.Key_Escape) {
                        root.cancel();
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        root.commit();
                    } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                        root.step(back ? -1 : 1);
                    } else if (event.key === Qt.Key_Right) {
                        root.step(1);
                    } else if (event.key === Qt.Key_Left) {
                        root.step(-1);
                    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
                        root.toggleRow();
                    } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                        root.selectSpace(event.key - Qt.Key_1);
                        root.appsFocused = false;
                    } else {
                        return;
                    }
                    event.accepted = true;
                }
                // Releasing SUPER confirms the selection (hold SUPER, tap TAB to cycle).
                Keys.onReleased: event => {
                    if (event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R || event.key === Qt.Key_Meta) {
                        root.commit();
                        event.accepted = true;
                    }
                }

                StyledRect {
                    id: island

                    anchors.horizontalCenter: parent.horizontalCenter
                    border.color: Colours.palette.m3outlineVariant
                    border.width: 1
                    clip: true
                    color: Colours.tPalette.m3surfaceContainer
                    height: content.implicitHeight + Tokens.padding.large * 2
                    opacity: root.presented ? 1 : 0
                    radius: Tokens.rounding.extraLarge
                    scale: root.presented ? 1 : 0.92
                    transform: Translate {
                        y: root.presented ? 0 : -island.height * 0.4

                        Behavior on y {
                            Anim {
                                type: Anim.FastSpatial
                            }
                        }
                    }
                    transformOrigin: Item.Top
                    width: Math.min(win.implicitWidth, Math.max(360, content.implicitWidth + Tokens.padding.extraLarge * 2))
                    y: Tokens.padding.medium

                    Behavior on height {
                        Anim {
                            type: Anim.FastSpatial
                        }
                    }
                    Behavior on opacity {
                        Anim {
                            type: Anim.FastEffects
                        }
                    }
                    Behavior on scale {
                        Anim {
                            type: Anim.FastSpatial
                        }
                    }
                    Behavior on width {
                        Anim {
                            type: Anim.FastSpatial
                        }
                    }

                    Column {
                        id: content

                        anchors.left: parent.left
                        anchors.margins: Tokens.padding.large
                        anchors.right: parent.right
                        anchors.top: parent.top
                        spacing: Tokens.spacing.medium

                        // Header: current selection
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: Tokens.spacing.small

                            MaterialIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                color: Colours.palette.m3primary
                                text: root.appsFocused ? "apps" : "grid_view"
                            }
                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                font: Tokens.font.title.small
                                text: root.apps.length > 0 ? qsTr("Không gian %1 • %2 ứng dụng").arg(root.selectedSpace?.id ?? "").arg(root.apps.length) : qsTr("Không gian %1 • trống").arg(root.selectedSpace?.id ?? "")
                            }
                        }

                        // Workspaces: the selected pill grows to show its number and label
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: Tokens.spacing.small

                            Repeater {
                                model: root.spaces

                                delegate: StyledRect {
                                    id: space

                                    required property int index
                                    required property var modelData
                                    readonly property bool selected: index === root.spaceIndex
                                    readonly property bool active: selected && !root.appsFocused

                                    color: active ? Colours.palette.m3primary : selected ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainerHigh
                                    implicitHeight: 38
                                    implicitWidth: selected ? 64 : 38
                                    radius: Tokens.rounding.full

                                    Behavior on color {
                                        CAnim {}
                                    }
                                    Behavior on implicitWidth {
                                        Anim {
                                            type: Anim.FastSpatial
                                        }
                                    }

                                    StyledText {
                                        anchors.centerIn: parent
                                        color: space.active ? Colours.palette.m3onPrimary : space.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                                        font: Tokens.font.label.large
                                        opacity: space.modelData.count > 0 || space.selected ? 1 : 0.45
                                        text: space.modelData.id
                                    }
                                    // Occupied indicator
                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: 4
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        color: space.active ? Colours.palette.m3onPrimary : Colours.palette.m3primary
                                        height: 4
                                        radius: 2
                                        visible: space.modelData.count > 0
                                        width: 4
                                    }
                                    TapHandler {
                                        onTapped: {
                                            root.selectSpace(space.index);
                                            root.appsFocused = false;
                                            root.commit();
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            color: Colours.palette.m3outlineVariant
                            height: 1
                            opacity: 0.6
                            width: parent.width
                        }

                        // Apps in the selected workspace
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: Tokens.spacing.medium
                            visible: root.apps.length > 0

                            Repeater {
                                model: root.apps

                                delegate: Item {
                                    id: app

                                    required property int index
                                    required property var modelData
                                    readonly property bool selected: index === root.appIndex && root.appsFocused

                                    implicitHeight: 96
                                    implicitWidth: 96

                                    StyledRect {
                                        anchors.fill: parent
                                        border.color: Colours.palette.m3primary
                                        border.width: app.selected ? 2 : 0
                                        color: app.selected ? Colours.tPalette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHigh
                                        opacity: app.selected ? 1 : 0.8
                                        radius: Tokens.rounding.large
                                        scale: app.selected ? 1 : 0.94

                                        Behavior on opacity {
                                            Anim {
                                                type: Anim.FastEffects
                                            }
                                        }
                                        Behavior on scale {
                                            Anim {
                                                type: Anim.FastSpatial
                                            }
                                        }

                                        IconImage {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            anchors.top: parent.top
                                            anchors.topMargin: Tokens.padding.medium
                                            implicitSize: 46
                                            source: Icons.getAppIcon(app.modelData?.lastIpcObject?.class ?? "", "image-missing")
                                        }
                                        StyledText {
                                            anchors.bottom: parent.bottom
                                            anchors.bottomMargin: Tokens.padding.small
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            color: app.selected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                                            elide: Text.ElideRight
                                            font: Tokens.font.label.small
                                            horizontalAlignment: Text.AlignHCenter
                                            text: app.modelData?.title ?? ""
                                            width: parent.width - Tokens.padding.medium * 2
                                        }
                                        TapHandler {
                                            onTapped: {
                                                root.appIndex = app.index;
                                                root.appsFocused = true;
                                                root.commit();
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Empty workspace
                        Column {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: Tokens.spacing.extraSmall
                            visible: root.apps.length === 0

                            MaterialIcon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: Colours.palette.m3outline
                                fontStyle: Tokens.font.icon.extraLarge
                                text: "desktop_windows"
                            }
                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: Colours.palette.m3outline
                                font: Tokens.font.label.medium
                                text: qsTr("Không gian trống")
                            }
                        }

                        StyledText {
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                            horizontalAlignment: Text.AlignHCenter
                            text: qsTr("SUPER+Tab: không gian  •  SUPER+Shift+Tab: ứng dụng  •  Thả SUPER để mở")
                            width: parent.width
                        }
                    }
                }
            }
        }
    }
}
