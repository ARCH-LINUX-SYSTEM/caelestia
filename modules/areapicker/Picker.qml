pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services
import qs.utils

MouseArea {
    id: root

    required property LazyLoader loader
    required property ShellScreen screen

    property bool onClient

    property real realBorderWidth: onClient ? (Hypr.options["general:border_size"] ?? 1) : 2
    property real realRounding: onClient ? (Hypr.options["decoration:rounding"] ?? 0) : 0

    property real ssx
    property real ssy

    property real sx: 0
    property real sy: 0
    property real ex: screen.width
    property real ey: screen.height

    property real rsx: Math.min(sx, ex)
    property real rsy: Math.min(sy, ey)
    property real sw: Math.abs(sx - ex)
    property real sh: Math.abs(sy - ey)
    readonly property int snapPadding: GlobalConfig.regionSelector.targetRegions.selectionPadding

    property list<var> clients: {
        const mon = Hypr.monitorFor(screen);
        if (!mon)
            return [];

        const special = mon.lastIpcObject.specialWorkspace;
        const wsId = special.name ? special.id : mon.activeWorkspace.id;

        return Hypr.toplevels.values.filter(c => c.workspace?.id === wsId).sort((a, b) => {
            // Pinned first, then fullscreen, then floating, then any other
            const ac = a.lastIpcObject;
            const bc = b.lastIpcObject;
            return (bc.pinned - ac.pinned) || ((bc.fullscreen !== 0) - (ac.fullscreen !== 0)) || (bc.floating - ac.floating);
        });
    }

    function checkClientRects(x: real, y: real): void {
        if (!GlobalConfig.regionSelector.targetRegions.windows) {
            onClient = false;
            return;
        }

        let matched = false;
        for (const client of clients) {
            if (!client)
                continue;

            let {
                at: [cx, cy],
                size: [cw, ch]
            } = client.lastIpcObject;
            cx -= screen.x;
            cy -= screen.y;
            if (cx <= x && cy <= y && cx + cw >= x && cy + ch >= y) {
                const padding = snapPadding;
                onClient = true;
                sx = Math.max(0, cx - padding);
                sy = Math.max(0, cy - padding);
                ex = Math.min(screen.width, cx + cw + padding);
                ey = Math.min(screen.height, cy + ch + padding);
                matched = true;
                break;
            }
        }
        if (!matched)
            onClient = false;
    }

    function copyScreenshot(path: string): void {
        const saveDir = Paths.absolutePath(GlobalConfig.paths.screenSnipDir.trim());
        if (!saveDir) {
            Quickshell.execDetached(["sh", "-c", "wl-copy --type image/png < \"$1\"", "caelestia-picker", path]);
            Quickshell.execDetached(["notify-send", "-a", "caelestia-cli", "-i", path, "Đã chụp màn hình", "Đã sao chép ảnh vào bảng nhớ tạm"]);
            return;
        }

        Quickshell.execDetached([
            "sh",
            "-c",
            "set -e; mkdir -p -- \"$1\"; dest=\"$1/screenshot-$(date '+%Y-%m-%d_%H.%M.%S').png\"; cp -- \"$2\" \"$dest\"; wl-copy --type image/png < \"$dest\"; notify-send -a caelestia-cli -i \"$dest\" 'Đã chụp màn hình' \"Đã lưu vào $dest và sao chép vào bảng nhớ tạm\"",
            "caelestia-picker",
            saveDir,
            path
        ]);
    }

    function annotateScreenshot(path: string): void {
        if (GlobalConfig.regionSelector.annotation.useSatty) {
            Quickshell.execDetached([
                "sh",
                "-c",
                "if command -v satty >/dev/null 2>&1; then exec satty -f \"$1\"; else exec swappy -f \"$1\"; fi",
                "caelestia-picker",
                path
            ]);
        } else {
            Quickshell.execDetached(["swappy", "-f", path]);
        }
    }

    function save(): void {
        const tmpfile = Qt.resolvedUrl(`/tmp/caelestia-picker-${Quickshell.processId}-${Date.now()}.png`);
        CUtils.saveItem(screencopy, tmpfile, Qt.rect(Math.ceil(rsx), Math.ceil(rsy), Math.floor(sw), Math.floor(sh)), path => {
            if (root.loader.clipboardOnly) {
                root.copyScreenshot(path);
            } else {
                root.annotateScreenshot(path);
            }
            closeAnim.start();
        });
    }

    onClientsChanged: checkClientRects(mouseX, mouseY)

    anchors.fill: parent
    opacity: 0
    hoverEnabled: true
    cursorShape: Qt.CrossCursor

    Component.onCompleted: {
        Hypr.extras.refreshOptions();

        // Break binding if frozen
        if (loader.freeze)
            clients = clients;

        opacity = 1;

        const c = clients[0];
        if (c && GlobalConfig.regionSelector.targetRegions.windows) {
            const cx = c.lastIpcObject.at[0] - screen.x;
            const cy = c.lastIpcObject.at[1] - screen.y;
            const padding = snapPadding;
            onClient = true;
            sx = Math.max(0, cx - padding);
            sy = Math.max(0, cy - padding);
            ex = Math.min(screen.width, cx + c.lastIpcObject.size[0] + padding);
            ey = Math.min(screen.height, cy + c.lastIpcObject.size[1] + padding);
        } else {
            sx = screen.width / 2 - 100;
            sy = screen.height / 2 - 100;
            ex = screen.width / 2 + 100;
            ey = screen.height / 2 + 100;
        }
    }

    onPressed: event => {
        ssx = event.x;
        ssy = event.y;
    }

    onReleased: {
        if (closeAnim.running)
            return;

        if (root.loader.freeze) {
            save();
        } else {
            overlay.visible = border.visible = false;
            screencopy.visible = false;
            screencopy.active = true;
        }
    }

    onPositionChanged: event => {
        const x = event.x;
        const y = event.y;

        if (pressed) {
            onClient = false;
            sx = ssx;
            sy = ssy;
            ex = x;
            ey = y;
        } else {
            checkClientRects(x, y);
        }
    }

    focus: true
    Keys.onEscapePressed: closeAnim.start()

    SequentialAnimation {
        id: closeAnim

        PropertyAction {
            target: root.loader
            property: "closing"
            value: true
        }
        ParallelAnimation {
            Anim {
                target: root
                property: "opacity"
                to: 0
                type: Anim.StandardLarge
            }
            Anim {
                target: root
                properties: "rsx,rsy"
                to: 0
            }
            Anim {
                target: root
                property: "sw"
                to: root.screen.width
            }
            Anim {
                target: root
                property: "sh"
                to: root.screen.height
            }
        }
        PropertyAction {
            target: root.loader
            property: "activeAsync"
            value: false
        }
    }

    Process {
        running: true
        command: ["hyprctl", "cursorpos", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                const pos = JSON.parse(text);
                root.checkClientRects(pos.x - root.screen.x, pos.y - root.screen.y);
            }
        }
    }

    Loader {
        id: screencopy

        asynchronous: true
        anchors.fill: parent

        active: root.loader.freeze

        sourceComponent: ScreencopyView {
            captureSource: root.screen

            onHasContentChanged: {
                if (hasContent && !root.loader.freeze) {
                    overlay.visible = border.visible = true;
                    root.save();
                }
            }
        }
    }

    StyledRect {
        id: overlay

        anchors.fill: parent
        color: Colours.palette.m3secondaryContainer
        opacity: GlobalConfig.regionSelector.targetRegions.opacity

        layer.enabled: true
        layer.effect: Mask {
            maskSource: selectionWrapper
            maskInverted: true
        }
    }

    Rectangle {
        color: Colours.palette.m3primaryContainer
        opacity: GlobalConfig.regionSelector.targetRegions.content ? 1 - GlobalConfig.regionSelector.targetRegions.contentRegionOpacity : 0
        radius: root.realRounding
        x: root.rsx
        y: root.rsy
        width: root.sw
        height: root.sh
    }

    Rectangle {
        visible: GlobalConfig.regionSelector.rect.showAimLines && !root.pressed
        color: Colours.palette.m3primary
        opacity: 0.45
        x: Math.round(root.mouseX)
        width: 1
        height: parent.height
    }

    Rectangle {
        visible: GlobalConfig.regionSelector.rect.showAimLines && !root.pressed
        color: Colours.palette.m3primary
        opacity: 0.45
        y: Math.round(root.mouseY)
        width: parent.width
        height: 1
    }

    Item {
        id: selectionWrapper

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            id: selectionRect

            radius: root.realRounding
            x: root.rsx
            y: root.rsy
            implicitWidth: root.sw
            implicitHeight: root.sh
        }
    }

    StyledRect {
        visible: GlobalConfig.regionSelector.targetRegions.showLabel && root.sw > 0 && root.sh > 0
        color: Colours.palette.m3primaryContainer
        radius: Tokens.rounding.full
        x: Math.max(0, Math.min(root.width - width, root.rsx + root.sw / 2 - width / 2))
        y: root.rsy > height + Tokens.spacing.small ? root.rsy - height - Tokens.spacing.small : Math.min(root.height - height, root.rsy + root.sh + Tokens.spacing.small)
        implicitWidth: dimensions.implicitWidth + Tokens.padding.large * 2
        implicitHeight: dimensions.implicitHeight + Tokens.padding.small * 2

        StyledText {
            id: dimensions

            anchors.centerIn: parent
            color: Colours.palette.m3onPrimaryContainer
            font: Tokens.font.label.medium
            text: qsTr("%1 × %2 px").arg(Math.round(root.sw)).arg(Math.round(root.sh))
        }
    }

    Rectangle {
        id: border

        color: "transparent"
        radius: root.realRounding > 0 ? root.realRounding + root.realBorderWidth : 0
        border.width: root.realBorderWidth
        border.color: Colours.palette.m3primary

        x: selectionRect.x - root.realBorderWidth
        y: selectionRect.y - root.realBorderWidth
        implicitWidth: selectionRect.implicitWidth + root.realBorderWidth * 2
        implicitHeight: selectionRect.implicitHeight + root.realBorderWidth * 2

        Behavior on border.color {
            CAnim {}
        }
    }

    Behavior on opacity {
        Anim {
            type: Anim.StandardLarge
        }
    }

    Behavior on rsx {
        enabled: !root.pressed

        Anim {}
    }

    Behavior on rsy {
        enabled: !root.pressed

        Anim {}
    }

    Behavior on sw {
        enabled: !root.pressed

        Anim {}
    }

    Behavior on sh {
        enabled: !root.pressed

        Anim {}
    }
}
