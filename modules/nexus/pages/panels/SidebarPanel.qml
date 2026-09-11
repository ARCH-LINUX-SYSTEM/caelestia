pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Thanh bên")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Chung")
        }

        ToggleRow {
            first: true
            text: qsTr("Đã bật")
            checked: Config.sidebar.enabled
            onToggled: GlobalConfig.sidebar.enabled = checked
        }

        ToggleRow {
            text: qsTr("Hiện khi rê chuột")
            subtext: qsTr("Mở thanh bên khi con trỏ chạm cạnh phải")
            checked: Config.sidebar.showOnHover
            onToggled: GlobalConfig.sidebar.showOnHover = checked
        }

        StepperRow {
            enabled: Config.sidebar.showOnHover
            opacity: enabled ? 1 : 0.55
            label: qsTr("Vùng kích hoạt tối thiểu")
            subtext: qsTr("Bỏ qua phần trên của cạnh phải để tránh xung đột thông báo (px)")
            value: Config.sidebar.minHoverThreshold
            from: 0
            to: 1000
            stepSize: 10
            onMoved: v => GlobalConfig.sidebar.minHoverThreshold = Math.round(v)
        }

        StepperRow {
            last: true
            label: qsTr("Ngưỡng kéo")
            subtext: qsTr("Số pixel kéo trước khi thanh bên mở")
            value: Config.sidebar.dragThreshold
            from: 0
            to: 200
            stepSize: 5
            onMoved: v => GlobalConfig.sidebar.dragThreshold = v
        }

        SectionHeader {
            text: qsTr("Nội dung")
        }

        NavRow {
            first: true
            last: true
            icon: "toggle_on"
            label: qsTr("Bật/tắt nhanh")
            status: qsTr("Chọn và sắp xếp các nút trong bảng tiện ích")
            onClicked: root.nState.openSubPage(11)
        }
    }
}
