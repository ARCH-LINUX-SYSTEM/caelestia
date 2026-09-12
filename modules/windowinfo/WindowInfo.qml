import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property ShellScreen screen
    required property HyprlandToplevel client

    readonly property real availableWidth: Math.max(1, screen.width - Tokens.padding.extraLargeIncreased * 2)
    readonly property real detailsWidth: Math.min(Tokens.sizes.winfo.detailsWidth, availableWidth * 0.46)
    readonly property real previewWidth: Math.max(1, availableWidth - detailsWidth - Tokens.spacing.medium - Tokens.padding.large * 2)

    implicitWidth: Math.min(child.implicitWidth, availableWidth)
    implicitHeight: screen.height * Tokens.sizes.winfo.heightMult

    RowLayout {
        id: child

        anchors.fill: parent
        anchors.margins: Tokens.padding.large

        spacing: Tokens.spacing.medium

        Preview {
            screen: root.screen
            client: root.client
            maximumWidth: root.previewWidth
        }

        ColumnLayout {
            spacing: Tokens.spacing.medium

            Layout.minimumWidth: 0
            Layout.preferredWidth: root.detailsWidth
            Layout.maximumWidth: root.detailsWidth
            Layout.fillHeight: true

            StyledRect {
                Layout.fillWidth: true
                Layout.fillHeight: true

                color: Colours.tPalette.m3surfaceContainer
                radius: Tokens.rounding.large
                clip: true

                Details {
                    client: root.client
                }
            }

            StyledRect {
                Layout.fillWidth: true
                Layout.preferredHeight: buttons.implicitHeight

                color: Colours.tPalette.m3surfaceContainer
                radius: Tokens.rounding.large

                Buttons {
                    id: buttons

                    client: root.client
                }
            }
        }
    }
}
