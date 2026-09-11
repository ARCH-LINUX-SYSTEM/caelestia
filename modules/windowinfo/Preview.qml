pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property ShellScreen screen
    required property HyprlandToplevel client
    required property real maximumWidth

    readonly property real contentMaximumWidth: Math.max(1, maximumWidth - Tokens.padding.extraLargeIncreased)

    Layout.minimumWidth: 0
    Layout.preferredWidth: Math.min(preview.implicitWidth + Tokens.padding.extraLargeIncreased, maximumWidth)
    Layout.maximumWidth: maximumWidth
    Layout.fillHeight: true

    StyledClippingRect {
        id: preview

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.bottom: label.top
        anchors.topMargin: Tokens.padding.large
        anchors.bottomMargin: Tokens.spacing.medium

        implicitWidth: view.implicitWidth
        width: Math.min(preview.implicitWidth, root.contentMaximumWidth)

        color: Colours.tPalette.m3surfaceContainer
        radius: Tokens.rounding.medium

        Loader {
            asynchronous: true
            anchors.centerIn: parent
            active: !root.client

            sourceComponent: ColumnLayout {
                spacing: 0

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "web_asset_off"
                    color: Colours.palette.m3outline
                    fontStyle: Tokens.font.icon.builders.extraLarge.scale(3).build()
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Không có cửa sổ đang hoạt động")
                    color: Colours.palette.m3outline
                    font: Tokens.font.body.builders.large.size(28).weight(Font.Medium).build()
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Hãy thử chuyển sang một cửa sổ")
                    color: Colours.palette.m3outline
                    font: Tokens.font.body.large
                }
            }
        }

        ScreencopyView {
            id: view

            anchors.centerIn: parent

            captureSource: root.client?.wayland ?? null // qmllint disable unresolved-type
            live: true

            constraintSize.width: {
                const client = root.client;
                if (!client)
                    return Math.max(1, Math.min(root.contentMaximumWidth, parent.height));

                const screenRatio = root.screen.height > 0 ? root.screen.width / root.screen.height : 1;
                const clientSize = client.lastIpcObject.size ?? [1, 1];
                const clientRatio = clientSize[1] > 0 ? clientSize[0] / clientSize[1] : screenRatio;
                return Math.max(1, Math.min(root.contentMaximumWidth, parent.height * Math.min(screenRatio, clientRatio)));
            }
            constraintSize.height: parent.height
        }
    }

    StyledText {
        id: label

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Tokens.padding.large

        width: Math.max(1, root.width - Tokens.padding.large * 2)

        animate: true
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        text: {
            const client = root.client;
            if (!client)
                return qsTr("Không có cửa sổ đang hoạt động");

            const mon = client.monitor;
            const position = client.lastIpcObject.at ?? [];
            return qsTr("%1 trên màn hình %2 tại %3, %4").arg(client.title).arg(mon?.name ?? qsTr("không xác định")).arg(position[0] ?? -1).arg(position[1] ?? -1);
        }
    }
}
