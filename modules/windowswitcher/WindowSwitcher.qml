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

Scope {
    id: root

    property var clients: []
    property var mruAddresses: []
    property double openedAtMs
    property string originWorkspace: ""
    property bool overlayVisible
    property bool presented
    property int selectedIndex: -1
    property bool sticky
    property bool switching
    property string targetScreen: ""

    function activate(client: var): void {
        const selector = selectorFor(client);
        if (!selector)
            return;

        if (String(client.workspace?.name ?? "") === "special:minimized") {
            let moveRequest;
            if (Hypr.usingLua) {
                const windowArg = luaEscape(selector);
                const workspaceArg = luaEscape(originWorkspace);
                moveRequest = `hl.dsp.window.move({ window = "${windowArg}", workspace = "${workspaceArg}", follow = true })`;
            } else {
                moveRequest = `movetoworkspace ${originWorkspace},${selector}`;
            }

            const focusRequest = Hypr.usingLua ? `hl.dsp.focus({ window = "${luaEscape(selector)}" })` : `focuswindow ${selector}`;
            const requestPrefix = Hypr.usingLua ? "eval" : "dispatch";
            Hypr.extras.batchMessage([`${requestPrefix} ${moveRequest}`, `${requestPrefix} ${focusRequest}`]);
            return;
        }

        if (Hypr.usingLua)
            Hypr.dispatch(`hl.dsp.focus({ window = "${luaEscape(selector)}" })`);
        else
            Hypr.dispatch(`focuswindow ${selector}`);
    }
    function activeAddressFor(candidates: var): string {
        const reported = normaliseAddress(Hyprland.activeToplevel);
        if (reported && candidates.some(client => normaliseAddress(client) === reported))
            return reported;

        const activated = candidates.find(client => client.activated === true);
        if (activated)
            return normaliseAddress(activated);

        const focused = candidates.find(client => Number(client.lastIpcObject?.focusHistoryID ?? -1) === 0);
        return normaliseAddress(focused);
    }
    function cancel(): void {
        finish(false);
    }
    function commit(): void {
        finish(true);
    }
    function commitFromModifier(): void {
        if (!sticky)
            commit();
    }
    function currentNormalWorkspace(): string {
        let name = String(Hypr.focusedWorkspace?.name ?? "");
        if (!name || name.startsWith("special:"))
            name = String(Hypr.focusedMonitor?.activeWorkspace?.name ?? "");
        if (!name || name.startsWith("special:"))
            name = String(Hypr.activeWsId);
        return name;
    }
    function finish(activateSelection: bool): void {
        if (!switching)
            return;

        const selected = selectedIndex >= 0 && selectedIndex < clients.length ? clients[selectedIndex] : null;
        switching = false;
        sticky = false;
        presented = false;
        closeTimer.restart();

        if (activateSelection && selected)
            activate(selected);
    }
    function isSwitchable(client: var): bool {
        if (!client || !normaliseAddress(client))
            return false;

        const ipc = client.lastIpcObject ?? {};
        // Foreign-toplevel objects can outlive their Hyprland IPC entry briefly.
        // Only show clients confirmed by the current `hyprctl clients` snapshot.
        if (ipc.mapped !== true || ipc.hidden === true || ipc.noFocus === true)
            return false;

        return String(client.title ?? "").trim().length > 0 || String(ipc.class ?? "").trim().length > 0;
    }
    function luaEscape(value: string): string {
        return value.replace(/\\/g, "\\\\").replace(/\"/g, "\\\"");
    }
    function normaliseAddress(client: var): string {
        const address = String(client?.address ?? "");
        return address.startsWith("0x") ? address.slice(2) : address;
    }
    function orderedClients(): var {
        const unique = new Map();
        for (const client of Hypr.toplevels.values) {
            if (isSwitchable(client))
                unique.set(normaliseAddress(client), client);
        }

        const allClients = Array.from(unique.values());
        const activeAddress = activeAddressFor(allClients);
        const order = new Map();
        for (let i = 0; i < mruAddresses.length; ++i)
            order.set(mruAddresses[i], i);

        const ordered = allClients.sort((a, b) => {
            const aa = normaliseAddress(a);
            const ba = normaliseAddress(b);
            if (aa === activeAddress)
                return -1;
            if (ba === activeAddress)
                return 1;

            const ai = order.has(aa) ? order.get(aa) : Number.MAX_SAFE_INTEGER;
            const bi = order.has(ba) ? order.get(ba) : Number.MAX_SAFE_INTEGER;
            if (ai !== bi)
                return ai - bi;

            const ah = Number(a.lastIpcObject?.focusHistoryID ?? Number.MAX_SAFE_INTEGER);
            const bh = Number(b.lastIpcObject?.focusHistoryID ?? Number.MAX_SAFE_INTEGER);
            if (ah !== bh)
                return ah - bh;
            return String(a.title ?? "").localeCompare(String(b.title ?? ""));
        });
        if (GlobalConfig.overview.orderRightLeft || (GlobalConfig.overview.style === "niri" && GlobalConfig.overview.orderBottomUp))
            ordered.reverse();
        return ordered;
    }
    function reconcileClients(): void {
        if (!switching)
            return;

        const selectedAddress = normaliseAddress(clients[selectedIndex]);
        const available = orderedClients();
        if (available.length === 0) {
            cancel();
            return;
        }

        clients = available;
        const newIndex = available.findIndex(client => normaliseAddress(client) === selectedAddress);
        selectedIndex = newIndex >= 0 ? newIndex : Math.min(selectedIndex, available.length - 1);
    }
    function rememberActive(client: var): void {
        if (switching || !client)
            return;

        const address = normaliseAddress(client);
        if (!address)
            return;

        const updated = mruAddresses.filter(a => a !== address);
        updated.unshift(address);
        mruAddresses = updated.slice(0, 128);
    }
    function screenForActiveMonitor(): string {
        const monitor = Hypr.focusedMonitor;
        const screen = Screens.screens.find(s => Hypr.monitorFor(s) === monitor);
        return screen?.name ?? Screens.screens[0]?.name ?? "";
    }
    function selectorFor(client: var): string {
        const address = normaliseAddress(client);
        return address ? `address:0x${address}` : "";
    }
    function start(direction: int, stayOpen: bool): void {
        if (!GlobalConfig.overview.enabled)
            return;

        if (switching) {
            if (stayOpen)
                sticky = true;
            step(direction);
            return;
        }

        const available = orderedClients();
        if (available.length === 0)
            return;

        const activeAddress = activeAddressFor(available);
        const activeIndex = available.findIndex(client => normaliseAddress(client) === activeAddress);
        closeTimer.stop();
        clients = available;
        originWorkspace = currentNormalWorkspace();
        targetScreen = screenForActiveMonitor();
        switching = true;
        sticky = stayOpen;
        overlayVisible = true;
        openedAtMs = Date.now();
        selectedIndex = activeIndex >= 0 ? (activeIndex + direction + available.length) % available.length : direction >= 0 ? 0 : available.length - 1;

        Qt.callLater(() => {
            if (root.switching)
                root.presented = true;
        });
    }
    function step(direction: int): void {
        if (!switching) {
            start(direction, false);
            return;
        }
        if (clients.length === 0) {
            cancel();
            return;
        }

        selectedIndex = (selectedIndex + direction + clients.length) % clients.length;
    }

    Component.onCompleted: rememberActive(Hyprland.activeToplevel)

    Timer {
        id: closeTimer

        interval: 180

        onTriggered: {
            root.overlayVisible = false;
            root.clients = [];
            root.selectedIndex = -1;
        }
    }
    Timer {
        id: reconcileTimer

        interval: 60

        onTriggered: root.reconcileClients()
    }
    Connections {
        function onActiveToplevelChanged(): void {
            root.rememberActive(Hyprland.activeToplevel);
        }
        function onRawEvent(event: HyprlandEvent): void {
            if (root.switching && ["openwindow", "closewindow", "movewindow", "movewindowv2", "minimize"].includes(event.name))
                reconcileTimer.restart();
        }

        target: Hyprland
    }
    Connections {
        function onValuesChanged(): void {
            if (root.switching)
                reconcileTimer.restart();
        }

        target: Hypr.toplevels
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        description: qsTr("Chuyển tới cửa sổ tiếp theo")
        // qmllint enable unresolved-type
        name: "windowSwitcherNext"

        onPressed: root.start(1, false)
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        description: qsTr("Chuyển tới cửa sổ trước")
        // qmllint enable unresolved-type
        name: "windowSwitcherPrev"

        onPressed: root.start(-1, false)
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        description: qsTr("Mở cửa sổ đã chọn")
        // qmllint enable unresolved-type
        name: "windowSwitcherCommit"

        onReleased: root.commitFromModifier()
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        description: qsTr("Mở bộ chuyển cửa sổ và giữ lại")
        // qmllint enable unresolved-type
        name: "windowSwitcherStickyNext"

        onPressed: root.start(1, true)
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        description: qsTr("Mở bộ chuyển cửa sổ ngược và giữ lại")
        // qmllint enable unresolved-type
        name: "windowSwitcherStickyPrev"

        onPressed: root.start(-1, true)
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        description: qsTr("Mở Task View")
        // qmllint enable unresolved-type
        name: "windowSwitcherTaskView"

        onPressed: root.start(0, true)
    }
    IpcHandler {
        function cancel(): void {
            root.cancel();
        }
        function commit(): void {
            root.commit();
        }
        function next(): void {
            root.start(1, false);
        }
        function previous(): void {
            root.start(-1, false);
        }
        function state(): string {
            return JSON.stringify({
                switching: root.switching,
                selectedIndex: root.selectedIndex,
                selectedAddress: root.normaliseAddress(root.clients[root.selectedIndex]),
                count: root.clients.length,
                sticky: root.sticky
            });
        }

        target: "windowSwitcher"
    }
    Variants {
        model: Screens.screens

        StyledWindow {
            id: win

            readonly property bool niriStyle: GlobalConfig.overview.style === "niri"
            readonly property real overviewScale: Math.max(0.25, GlobalConfig.overview.scale / 0.18)
            readonly property real cardWidth: Math.min(520, Math.max(140, Math.min(320, Math.max(210, width * 0.22)) * overviewScale))
            readonly property real cardHeight: Math.min(cardWidth * (niriStyle ? 0.56 : 0.68), height * (niriStyle ? 0.3 : 0.42))
            required property ShellScreen modelData
            readonly property real outerMargin: Math.max(20, Math.min(width, height) * 0.035)

            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: root.switching && visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            WlrLayershell.layer: WlrLayer.Overlay
            anchors.bottom: true
            anchors.left: true
            anchors.right: true
            anchors.top: true
            color: "transparent"
            name: "window-switcher"
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
                    if (event.key === Qt.Key_Escape) {
                        root.cancel();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        root.commit();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                        // The Tab that opened the layer can arrive once more while keyboard
                        // focus is being transferred. Ignore only that immediate duplicate.
                        if (Date.now() - root.openedAtMs >= 90)
                            root.step(event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier) ? -1 : 1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                        root.step(-1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
                        root.step(1);
                        event.accepted = true;
                    }
                }
                Keys.onReleased: event => {
                    if (event.key === Qt.Key_Alt || event.key === Qt.Key_AltGr) {
                        root.commitFromModifier();
                        event.accepted = true;
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: Colours.palette.m3scrim
                    opacity: root.presented ? 0.48 : 0

                    Behavior on opacity {
                        Anim {
                            type: Anim.FastEffects
                        }
                    }

                    TapHandler {
                        onTapped: root.cancel()
                    }
                }
                Rectangle {
                    id: panel

                    anchors.centerIn: parent
                    border.color: Colours.palette.m3outlineVariant
                    border.width: 1
                    clip: true
                    color: Colours.tPalette.m3surfaceContainer
                    height: content.implicitHeight + Tokens.padding.extraLarge * 2
                    opacity: root.presented ? 1 : 0
                    radius: Tokens.rounding.extraLarge
                    scale: root.presented ? 1 : 0.96
                    width: {
                        const visibleCards = Math.min(root.clients.length, win.niriStyle ? GlobalConfig.overview.rows : GlobalConfig.overview.columns);
                        const cardsWidth = win.niriStyle ? win.cardWidth : visibleCards * win.cardWidth + Math.max(0, visibleCards - 1) * Tokens.spacing.medium;
                        return Math.min(win.width - win.outerMargin * 2, Math.max(280, cardsWidth + Tokens.padding.extraLarge * 2));
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

                    Column {
                        id: content

                        anchors.left: parent.left
                        anchors.margins: Tokens.padding.extraLarge
                        anchors.right: parent.right
                        anchors.top: parent.top
                        spacing: Tokens.spacing.medium

                        StyledText {
                            elide: Text.ElideRight
                            font: Tokens.font.title.medium
                            horizontalAlignment: Text.AlignHCenter
                            text: qsTr("Chuyển cửa sổ")
                            width: parent.width
                        }
                        ListView {
                            id: list

                            x: Math.max(0, (parent.width - width) / 2)
                            clip: true
                            currentIndex: root.selectedIndex
                            height: win.niriStyle ? Math.min(win.height * 0.62, Math.min(root.clients.length, GlobalConfig.overview.rows) * win.cardHeight + Math.max(0, Math.min(root.clients.length, GlobalConfig.overview.rows) - 1) * Tokens.spacing.medium) : win.cardHeight
                            highlightFollowsCurrentItem: true
                            highlightMoveDuration: Tokens.anim.durations.expressiveFastSpatial
                            highlightRangeMode: ListView.ApplyRange
                            highlightResizeDuration: 0
                            model: win.visible ? root.clients : []
                            orientation: win.niriStyle ? ListView.Vertical : ListView.Horizontal
                            preferredHighlightBegin: Math.max(0, (win.niriStyle ? height : width) / 2 - (win.niriStyle ? win.cardHeight : win.cardWidth) / 2)
                            preferredHighlightEnd: Math.min(win.niriStyle ? height : width, (win.niriStyle ? height : width) / 2 + (win.niriStyle ? win.cardHeight : win.cardWidth) / 2)
                            spacing: Tokens.spacing.medium
                            width: win.niriStyle ? win.cardWidth : parent.width

                            delegate: Item {
                                id: card

                                required property int index
                                required property var modelData
                                readonly property bool selected: index === root.selectedIndex

                                height: win.niriStyle ? win.cardHeight : list.height
                                opacity: selected ? 1 : 0.78
                                scale: selected ? 0.97 : 0.93
                                width: win.cardWidth

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

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 5
                                    clip: true
                                    color: card.selected ? Colours.tPalette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHigh
                                    radius: Tokens.rounding.large

                                    Behavior on color {
                                        CAnim {}
                                    }

                                    Rectangle {
                                        id: previewFrame

                                        anchors.bottom: details.top
                                        anchors.left: parent.left
                                        anchors.margins: Tokens.padding.small
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        clip: true
                                        color: Colours.palette.m3surface
                                        radius: Tokens.rounding.medium

                                        ScreencopyView {
                                            id: preview

                                            anchors.centerIn: parent
                                            captureSource: card.modelData?.wayland ?? null // qmllint disable unresolved-type
                                            constraintSize.height: parent.height
                                            constraintSize.width: parent.width
                                            height: Math.min(parent.height, implicitHeight)
                                            live: false
                                            width: Math.min(parent.width, implicitWidth)
                                        }
                                        Column {
                                            anchors.horizontalCenter: GlobalConfig.overview.centerIcons ? parent.horizontalCenter : undefined
                                            anchors.left: GlobalConfig.overview.centerIcons ? undefined : parent.left
                                            anchors.leftMargin: GlobalConfig.overview.centerIcons ? 0 : Tokens.padding.large
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: Tokens.spacing.extraSmall
                                            visible: !preview.hasContent

                                            MaterialIcon {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                color: Colours.palette.m3outline
                                                fontStyle: Tokens.font.icon.extraLarge
                                                text: "web_asset_off"
                                            }
                                            StyledText {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                color: Colours.palette.m3outline
                                                elide: Text.ElideRight
                                                horizontalAlignment: Text.AlignHCenter
                                                text: qsTr("Không có ảnh xem trước")
                                                width: Math.min(implicitWidth, previewFrame.width - Tokens.padding.large * 2)
                                            }
                                        }
                                    }
                                    Item {
                                        id: details

                                        anchors.bottom: parent.bottom
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        height: Math.max(icon.height, title.implicitHeight + workspace.implicitHeight) + Tokens.padding.medium * 2

                                        IconImage {
                                            id: icon

                                            anchors.left: parent.left
                                            anchors.leftMargin: Tokens.padding.medium
                                            anchors.verticalCenter: parent.verticalCenter
                                            implicitSize: 34
                                            source: Icons.getAppIcon(card.modelData?.lastIpcObject.class ?? "", "image-missing")
                                        }
                                        StyledText {
                                            id: title

                                            anchors.left: icon.right
                                            anchors.leftMargin: Tokens.spacing.medium
                                            anchors.right: parent.right
                                            anchors.rightMargin: Tokens.padding.medium
                                            anchors.top: parent.top
                                            anchors.topMargin: Tokens.padding.medium
                                            elide: Text.ElideRight
                                            font: Tokens.font.body.medium
                                            text: card.modelData?.title ?? qsTr("Cửa sổ không có tiêu đề")
                                        }
                                        StyledText {
                                            id: workspace

                                            anchors.left: title.left
                                            anchors.right: title.right
                                            anchors.top: title.bottom
                                            color: Colours.palette.m3onSurfaceVariant
                                            elide: Text.ElideRight
                                            font: Tokens.font.label.small
                                            text: card.modelData?.workspace?.name === "special:minimized" ? qsTr("Đã thu nhỏ") : qsTr("Không gian %1").arg(card.modelData?.workspace?.name ?? "?")
                                        }
                                    }
                                    TapHandler {
                                        onTapped: {
                                            root.selectedIndex = card.index;
                                            root.commit();
                                        }
                                    }
                                }
                            }
                            highlight: Rectangle {
                                border.color: Colours.palette.m3primary
                                border.width: 3
                                color: "transparent"
                                height: win.niriStyle ? win.cardHeight : list.height
                                radius: Tokens.rounding.large
                                width: win.cardWidth
                            }
                        }
                        StyledText {
                            color: Colours.palette.m3onSurfaceVariant
                            elide: Text.ElideRight
                            font: Tokens.font.label.medium
                            horizontalAlignment: Text.AlignHCenter
                            text: root.sticky ? qsTr("Tab/phím mũi tên để chọn • Enter để mở • Esc để hủy") : qsTr("Giữ Alt và nhấn Tab để chọn • Thả Alt để mở • Esc để hủy")
                            width: parent.width
                        }
                    }
                }
            }
        }
    }
}
