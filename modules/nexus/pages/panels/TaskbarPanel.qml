pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Thanh tác vụ")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Behaviour
        SectionHeader {
            first: true
            text: qsTr("Hành vi")
        }

        ToggleRow {
            first: true
            text: qsTr("Luôn hiện")
            subtext: qsTr("Luôn giữ thanh hiển thị")
            checked: Config.bar.persistent
            onToggled: GlobalConfig.bar.persistent = checked
        }

        ToggleRow {
            text: qsTr("Hiện khi rê chuột")
            subtext: qsTr("Hiện thanh khi con trỏ chạm cạnh màn hình")
            checked: Config.bar.showOnHover
            onToggled: GlobalConfig.bar.showOnHover = checked
        }

        StepperRow {
            last: true
            label: qsTr("Ngưỡng kéo")
            subtext: qsTr("Số pixel kéo trước khi thanh hiện ra")
            value: Config.bar.dragThreshold
            from: 0
            to: 200
            stepSize: 5
            onMoved: v => GlobalConfig.bar.dragThreshold = v
        }

        // Components
        SectionHeader {
            text: qsTr("Thành phần")
        }

        NavRow {
            first: true
            icon: "workspaces"
            label: qsTr("Không gian làm việc")
            status: qsTr("Chỉ báo, biểu tượng cửa sổ")
            onClicked: root.nState.openSubPage(5)
        }

        NavRow {
            icon: "web_asset"
            label: qsTr("Cửa sổ đang hoạt động")
            status: qsTr("Hiển thị tiêu đề, bảng bật ra")
            onClicked: root.nState.openSubPage(6)
        }

        NavRow {
            icon: "widgets"
            label: qsTr("Khay hệ thống")
            status: qsTr("Biểu tượng khay hệ thống")
            onClicked: root.nState.openSubPage(7)
        }

        NavRow {
            icon: "signal_cellular_alt"
            label: qsTr("Biểu tượng trạng thái")
            status: qsTr("Chỉ báo hiển thị")
            onClicked: root.nState.openSubPage(8)
        }

        NavRow {
            icon: "schedule"
            label: qsTr("Đồng hồ")
            status: qsTr("Ngày, biểu tượng, nền")
            onClicked: root.nState.openSubPage(9)
        }

        NavRow {
            icon: "view_list"
            label: qsTr("Bố cục")
            status: qsTr("Bật, tắt, sắp xếp thành phần và loại trừ màn hình")
            onClicked: root.nState.openSubPage(10)
        }

        NavRow {
            last: true
            icon: "tune"
            label: qsTr("Tùy chọn mở rộng")
            status: qsTr("Tự ẩn, tài nguyên, thời tiết, media và nút tiện ích")
            onClicked: root.nState.openSubPage(12)
        }

        // Scroll actions
        SectionHeader {
            text: qsTr("Thao tác cuộn")
        }

        ToggleRow {
            first: true
            text: qsTr("Không gian làm việc")
            subtext: qsTr("Cuộn trên chỉ báo để chuyển không gian làm việc")
            checked: Config.bar.scrollActions.workspaces
            onToggled: GlobalConfig.bar.scrollActions.workspaces = checked
        }

        ToggleRow {
            text: qsTr("Âm lượng")
            subtext: qsTr("Cuộn ở nửa trên của thanh để chỉnh âm lượng")
            checked: Config.bar.scrollActions.volume
            onToggled: GlobalConfig.bar.scrollActions.volume = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Độ sáng")
            subtext: qsTr("Cuộn ở nửa dưới của thanh để chỉnh độ sáng")
            checked: Config.bar.scrollActions.brightness
            onToggled: GlobalConfig.bar.scrollActions.brightness = checked
        }
    }
}
