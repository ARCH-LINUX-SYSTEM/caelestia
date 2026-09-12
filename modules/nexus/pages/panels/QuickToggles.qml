pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property var toggleMetadata: ({
            "wifi": {
                label: qsTr("Wi-Fi"),
                icon: "wifi"
            },
            "bluetooth": {
                label: qsTr("Bluetooth"),
                icon: "bluetooth"
            },
            "mic": {
                label: qsTr("Micrô"),
                icon: "mic"
            },
            "settings": {
                label: qsTr("Cài đặt"),
                icon: "settings"
            },
            "gameMode": {
                label: qsTr("Chế độ trò chơi"),
                icon: "gamepad"
            },
            "dnd": {
                label: qsTr("Không làm phiền"),
                icon: "notifications_off"
            },
            "vpn": {
                label: "VPN",
                icon: "vpn_key"
            }
        })

    function copyToggles(): var {
        return [...GlobalConfig.utilities.quickToggles].map(toggle => Object.assign({}, toggle));
    }

    function setToggleEnabled(index: int, enabled: bool): void {
        const toggles = copyToggles();
        if (index < 0 || index >= toggles.length)
            return;
        toggles[index].enabled = enabled;
        GlobalConfig.utilities.quickToggles = toggles;
    }

    function moveToggle(index: int, offset: int): void {
        const toggles = copyToggles();
        const target = index + offset;
        if (index < 0 || index >= toggles.length || target < 0 || target >= toggles.length)
            return;
        const current = toggles[index];
        toggles[index] = toggles[target];
        toggles[target] = current;
        GlobalConfig.utilities.quickToggles = toggles;
    }

    function toggleLabel(toggle: var): string {
        return toggleMetadata[toggle.id]?.label ?? toggle.id ?? qsTr("Nút không rõ");
    }

    function toggleIcon(toggle: var): string {
        return toggleMetadata[toggle.id]?.icon ?? "extension";
    }

    title: qsTr("Bật/tắt nhanh")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Thứ tự và khả dụng")
        }

        Repeater {
            id: toggleList

            model: GlobalConfig.utilities.quickToggles

            ConnectedRect {
                id: toggleRow

                required property var modelData
                required property int index

                Layout.fillWidth: true
                first: index === 0
                last: index === toggleList.count - 1
                implicitHeight: toggleLayout.implicitHeight + toggleLayout.anchors.margins * 2

                RowLayout {
                    id: toggleLayout

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.largeIncreased
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        text: root.toggleIcon(toggleRow.modelData)
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.medium
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: root.toggleLabel(toggleRow.modelData)
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: toggleRow.modelData.id ?? ""
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                        }
                    }

                    StyledSwitch {
                        checked: toggleRow.modelData.enabled ?? true
                        onToggled: root.setToggleEnabled(toggleRow.index, checked)
                    }

                    IconButton {
                        icon: "arrow_upward"
                        type: IconButton.Tonal
                        disabled: toggleRow.index === 0
                        onClicked: root.moveToggle(toggleRow.index, -1)
                    }

                    IconButton {
                        icon: "arrow_downward"
                        type: IconButton.Tonal
                        disabled: toggleRow.index === toggleList.count - 1
                        onClicked: root.moveToggle(toggleRow.index, 1)
                    }
                }
            }
        }
    }
}
