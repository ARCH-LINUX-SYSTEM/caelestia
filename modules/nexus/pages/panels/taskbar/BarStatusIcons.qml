pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Biểu tượng trạng thái")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Visible icons
        SectionHeader {
            first: true
            text: qsTr("Biểu tượng hiển thị")
        }

        ToggleRow {
            first: true
            text: qsTr("Loa")
            checked: Config.bar.status.showAudio
            onToggled: GlobalConfig.bar.status.showAudio = checked
        }

        ToggleRow {
            text: qsTr("Micrô")
            checked: Config.bar.status.showMicrophone
            onToggled: GlobalConfig.bar.status.showMicrophone = checked
        }

        ToggleRow {
            text: qsTr("Bố cục bàn phím")
            checked: Config.bar.status.showKbLayout
            onToggled: GlobalConfig.bar.status.showKbLayout = checked
        }

        ToggleRow {
            text: qsTr("Mạng")
            checked: Config.bar.status.showNetwork
            onToggled: GlobalConfig.bar.status.showNetwork = checked
        }

        ToggleRow {
            text: qsTr("Wi-Fi")
            checked: Config.bar.status.showWifi
            onToggled: GlobalConfig.bar.status.showWifi = checked
        }

        ToggleRow {
            text: qsTr("Bluetooth")
            checked: Config.bar.status.showBluetooth
            onToggled: GlobalConfig.bar.status.showBluetooth = checked
        }

        ToggleRow {
            text: qsTr("Pin")
            checked: Config.bar.status.showBattery
            onToggled: GlobalConfig.bar.status.showBattery = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Khóa chữ hoa")
            checked: Config.bar.status.showLockStatus
            onToggled: GlobalConfig.bar.status.showLockStatus = checked
        }

        // Behaviour
        SectionHeader {
            text: qsTr("Hành vi")
        }

        ToggleRow {
            first: true
            last: true
            text: qsTr("Hiện bảng bật ra khi rê chuột")
            subtext: qsTr("Hiện bảng chi tiết khi rê chuột trên biểu tượng trạng thái")
            checked: Config.bar.popouts.statusIcons
            onToggled: GlobalConfig.bar.popouts.statusIcons = checked
        }
    }
}
