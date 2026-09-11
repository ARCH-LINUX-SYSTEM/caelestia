import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Bảng")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        NavRow {
            first: true
            icon: "dashboard"
            label: qsTr("Bảng điều khiển")
            status: Config.dashboard.enabled ? qsTr("Đã bật") : qsTr("Đã tắt")
            onClicked: root.nState.openSubPage(1)
        }

        NavRow {
            icon: "dock_to_bottom"
            label: qsTr("Thanh tác vụ")
            status: Config.bar.persistent ? qsTr("Luôn hiển thị") : Config.bar.showOnHover ? qsTr("Hiện khi rê chuột") : qsTr("Hiện khi kéo")
            onClicked: root.nState.openSubPage(2)
        }

        NavRow {
            icon: "apps"
            label: qsTr("Trình khởi chạy")
            status: Config.launcher.enabled ? qsTr("Đã bật") : qsTr("Đã tắt")
            onClicked: root.nState.openSubPage(3)
        }

        NavRow {
            last: true
            icon: "dock_to_right"
            label: qsTr("Thanh bên")
            status: Config.sidebar.enabled ? qsTr("Đã bật") : qsTr("Đã tắt")
            onClicked: root.nState.openSubPage(4)
        }
    }
}
