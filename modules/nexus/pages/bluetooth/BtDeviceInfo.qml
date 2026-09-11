pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property BluetoothDevice device: nState.selectedBtDevice
    readonly property bool connected: device?.state === BluetoothDeviceState.Connected // qmllint disable unresolved-type
    readonly property bool loading: device?.state === BluetoothDeviceState.Connecting || device?.state === BluetoothDeviceState.Disconnecting // qmllint disable unresolved-type

    readonly property string statusText: {
        if (!device)
            return "";
        let s = connected ? qsTr("Đã kết nối") : (device.bonded ? qsTr("Đã ghép đôi") : qsTr("Chưa ghép đôi"));
        if (connected && device.batteryAvailable)
            s += " • " + Math.round(device.battery * 100) + "%";
        return s;
    }

    onDeviceChanged: {
        // Auto close when device lost
        if (!device)
            nState.closeSubPage();
    }

    title: device?.name ?? qsTr("Thiết bị")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Big buttons
        ButtonRow {
            Layout.bottomMargin: Tokens.spacing.large - parent.spacing
            Layout.alignment: Qt.AlignHCenter
            Layout.minimumWidth: Math.round(root.cappedWidth * 0.7)
            spacing: Tokens.spacing.small

            ButtonBase {
                id: forgetBtn

                fillWidth: true
                shapeMorph: true
                isRound: true

                inactiveColour: Colours.palette.m3errorContainer
                inactiveOnColour: Colours.palette.m3onErrorContainer

                implicitWidth: forgetBtnLayout.implicitWidth + Tokens.padding.extraLarge * 2
                implicitHeight: forgetBtnLayout.implicitHeight + Tokens.padding.medium * 2

                onClicked: {
                    root.device?.forget();
                    root.nState.closeSubPage();
                }

                ColumnLayout {
                    id: forgetBtnLayout

                    anchors.centerIn: parent
                    spacing: 0

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "delete"
                        color: forgetBtn.onColour
                        fontStyle: Tokens.font.icon.medium
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Quên")
                        color: forgetBtn.onColour
                    }
                }
            }

            ButtonBase {
                id: connectBtn

                fillWidth: true
                shapeMorph: true
                isRound: true

                inactiveColour: Colours.palette.m3primaryContainer
                inactiveOnColour: Colours.palette.m3onPrimaryContainer
                stateLayer.disabled: root.loading

                implicitWidth: connectBtnContent.implicitWidth + Tokens.padding.extraLarge * 2
                implicitHeight: connectBtnContent.implicitHeight + Tokens.padding.medium * 2

                onClicked: root.device.connected = !root.connected

                AnimLoader {
                    id: connectBtnContent

                    anchors.centerIn: parent
                    sourceComp: root.loading ? loadingComp : textComp
                    outAnimType: Anim.SlowEffects
                    inAnimType: Anim.SlowEffects
                }

                Component {
                    id: loadingComp

                    LoadingIndicator {
                        implicitSize: connectBtn.height - Tokens.padding.large * 2
                    }
                }

                Component {
                    id: textComp

                    ColumnLayout {
                        spacing: 0

                        MaterialIcon {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.connected ? "close" : "add"
                            color: connectBtn.inactiveOnColour
                            fontStyle: Tokens.font.icon.medium
                            animate: true
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.connected ? qsTr("Ngắt kết nối") : qsTr("Kết nối")
                            color: connectBtn.inactiveOnColour
                            animate: true
                        }
                    }
                }
            }
        }

        // Connection group
        ToggleRow {
            verticalPadding: Tokens.padding.large
            first: true
            text: qsTr("Tin cậy")
            subtext: qsTr("Cho phép thiết bị này tự động kết nối")
            checked: root.device?.trusted ?? false
            onToggled: {
                if (root.device)
                    root.device.trusted = checked;
            }
        }

        ToggleRow {
            verticalPadding: Tokens.padding.large
            text: qsTr("Đã chặn")
            subtext: qsTr("Ngăn thiết bị này kết nối")
            checked: root.device?.blocked ?? false
            onToggled: {
                if (root.device)
                    root.device.blocked = checked;
            }
        }

        ToggleRow {
            verticalPadding: Tokens.padding.large
            last: true
            text: qsTr("Cho phép đánh thức")
            subtext: qsTr("Cho phép thiết bị này đánh thức hệ thống")
            checked: root.device?.wakeAllowed ?? false
            onToggled: {
                if (root.device)
                    root.device.wakeAllowed = checked;
            }
        }

        // Information
        ConnectedRect {
            Layout.topMargin: Tokens.spacing.large - parent.spacing
            Layout.fillWidth: true
            implicitHeight: batteryLayout.implicitHeight + Tokens.padding.large * 2
            first: true

            ColumnLayout {
                id: batteryLayout

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.small

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.medium

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Pin")
                    }

                    StyledText {
                        text: root.device?.batteryAvailable ? Math.round(root.device.battery * 100) + "%" : qsTr("Không khả dụng")
                        color: Colours.palette.m3outline
                        font: Tokens.font.body.small
                    }
                }

                Loader {
                    Layout.fillWidth: true
                    active: root.device?.batteryAvailable ?? false
                    visible: active
                    asynchronous: true

                    sourceComponent: StyledProgressBar {
                        implicitHeight: Tokens.padding.medium
                        value: root.device.battery
                    }
                }
            }
        }

        ConnectedRect {
            Layout.fillWidth: true
            implicitHeight: addrLayout.implicitHeight + Tokens.padding.large * 2
            last: true

            RowLayout {
                id: addrLayout

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.medium

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Địa chỉ")
                }

                StyledText {
                    text: root.device?.address ?? ""
                    color: Colours.palette.m3outline
                    font: Tokens.font.body.small
                }
            }
        }
    }
}
