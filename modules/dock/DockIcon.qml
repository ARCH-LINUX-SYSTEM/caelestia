pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services
import qs.modules.launcher.services

Item {
    id: root

    required property var modelData
    required property real cellSize
    required property real rowHoverX
    required property bool monochrome
    required property bool showPinButton
    required property bool launching

    readonly property list<string> addresses: modelData.addresses ?? []
    readonly property bool running: addresses.length > 0
    readonly property bool pinned: modelData.pinned === true
    readonly property real distance: Math.abs(x + width / 2 - rowHoverX)
    readonly property real influence: cellSize * 1.6
    readonly property real magnification: rowHoverX < -99998 ? 1 : 1 + 0.4 * Math.max(0, 1 - distance / influence)

    property int cycleIndex: 0
    property real bounceOffset: 0

    signal launchRequested()

    function activate(): void {
        if (root.modelData.activateOverride) {
            root.modelData.activateOverride();
        } else if (root.running) {
            const address = root.addresses[root.cycleIndex % root.addresses.length];
            root.cycleIndex++;

            const normalised = address.startsWith("0x") ? address.slice(2) : address;
            const selector = `address:0x${normalised}`;
            if (Hypr.usingLua)
                Hypr.dispatch(`hl.dsp.focus({ window = "${selector}" })`);
            else
                Hypr.dispatch(`focuswindow ${selector}`);
        } else if (root.modelData.entry) {
            Apps.launch(root.modelData.entry);
            root.launchRequested();
        }
    }

    function togglePinned(): void {
        const id = root.modelData.id;
        const list = [...GlobalConfig.dock.pinnedApps];
        const idx = list.indexOf(id);
        if (idx >= 0)
            list.splice(idx, 1);
        else
            list.push(id);
        GlobalConfig.dock.pinnedApps = list;
    }

    implicitWidth: cellSize
    implicitHeight: cellSize
    scale: magnification
    transformOrigin: Item.Bottom

    transform: Translate {
        y: root.bounceOffset
    }

    Behavior on scale {
        Anim {
            type: Anim.FastSpatial
        }
    }

    // macOS-style launch bounce: rise (ease out, like a spring launch), fall
    // (ease in, like gravity), then a short pause before repeating. Stops as
    // soon as the launched app's window is detected (see DockWindow) or after
    // its launch timeout, whichever comes first.
    SequentialAnimation {
        running: root.launching
        loops: Animation.Infinite

        onRunningChanged: {
            if (!running)
                resetBounce.start();
        }

        NumberAnimation {
            target: root
            property: "bounceOffset"
            to: -root.cellSize * 0.45
            duration: 220
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: root
            property: "bounceOffset"
            to: 0
            duration: 240
            easing.type: Easing.InQuad
        }
        PauseAnimation {
            duration: 480
        }
    }

    NumberAnimation {
        id: resetBounce

        target: root
        property: "bounceOffset"
        to: 0
        duration: 150
        easing.type: Easing.OutQuad
    }

    StateLayer {
        id: stateLayer

        radius: Tokens.rounding.large

        onClicked: root.activate()
    }

    Loader {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -Tokens.spacing.extraSmall / 2
        asynchronous: true
        active: true

        sourceComponent: root.modelData.iconGlyph ? glyphIconComp : (root.monochrome ? colouredIconComp : iconComp)

        Component {
            id: glyphIconComp

            MaterialIcon {
                text: root.modelData.iconGlyph
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.size(root.cellSize * 0.5).build()
            }
        }

        Component {
            id: iconComp

            IconImage {
                asynchronous: true
                implicitSize: root.cellSize * 0.78
                source: Quickshell.iconPath(root.modelData.entry?.icon, "image-missing")
            }
        }

        Component {
            id: colouredIconComp

            ColouredIcon {
                asynchronous: true
                implicitSize: root.cellSize * 0.78
                source: Quickshell.iconPath(root.modelData.entry?.icon, "image-missing")
                colour: Colours.palette.m3onSurfaceVariant
            }
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: -Tokens.spacing.extraSmall
        implicitWidth: 5
        implicitHeight: 5
        radius: 2.5
        color: Colours.palette.m3primary
        opacity: root.running ? 1 : 0
        scale: root.running ? 1 : 0.3

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
    }

    Loader {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: -2
        asynchronous: true
        active: root.showPinButton
        opacity: root.showPinButton && (stateLayer.containsMouse || root.pinned) ? 1 : 0
        visible: opacity > 0
        sourceComponent: MaterialIcon {
            text: "push_pin"
            fill: root.pinned ? 1 : 0
            color: root.pinned ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.size(14).build()

            StateLayer {
                anchors.margins: -4
                radius: Tokens.rounding.full

                onClicked: root.togglePinned()
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.FastEffects
            }
        }
    }

    Loader {
        anchors.bottom: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: Tokens.spacing.small
        asynchronous: true
        active: true
        visible: opacity > 0
        // Stays mounted (rather than active: containsMouse) so hover-out plays a
        // proper closing fade+scale instead of the Loader destroying it mid-transition.
        opacity: stateLayer.containsMouse ? 1 : 0
        scale: stateLayer.containsMouse ? 1 : 0.85
        transformOrigin: Item.Bottom
        sourceComponent: StyledRect {
            implicitWidth: label.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: label.implicitHeight + Tokens.padding.small * 2
            radius: Tokens.rounding.medium
            color: Colours.palette.m3surfaceContainerHighest

            StyledText {
                id: label

                anchors.centerIn: parent
                text: root.modelData.name
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurface
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
    }
}
