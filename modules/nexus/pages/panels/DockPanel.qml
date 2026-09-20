pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Dock")
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
            subtext: qsTr("Hiện thanh Dock kiểu macOS ở cạnh dưới màn hình")
            checked: GlobalConfig.dock.enabled
            onToggled: GlobalConfig.dock.enabled = checked
        }

        ToggleRow {
            text: qsTr("Ghim khi khởi động")
            subtext: qsTr("Luôn hiển thị Dock thay vì chỉ hiện khi rê chuột")
            checked: GlobalConfig.dock.pinnedOnStartup
            onToggled: GlobalConfig.dock.pinnedOnStartup = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Hiện khi rê chuột")
            subtext: qsTr("Rê chuột xuống cạnh dưới để hiện Dock khi chưa ghim")
            checked: GlobalConfig.dock.hoverToReveal
            onToggled: GlobalConfig.dock.hoverToReveal = checked
        }

        StepperRow {
            first: true
            label: qsTr("Chiều cao")
            subtext: qsTr("Kích thước biểu tượng trong Dock (px)")
            value: GlobalConfig.dock.height
            from: 1
            to: 300
            stepSize: 4
            onMoved: value => GlobalConfig.dock.height = Math.round(value)
        }

        StepperRow {
            last: true
            label: qsTr("Vùng rê chuột")
            subtext: qsTr("Chiều cao vùng cạnh dưới dùng để phát hiện rê chuột khi Dock đang ẩn (px)")
            value: GlobalConfig.dock.hoverRegionHeight
            from: 0
            to: 100
            stepSize: 1
            onMoved: value => GlobalConfig.dock.hoverRegionHeight = Math.round(value)
        }

        SectionHeader {
            text: qsTr("Giao diện")
        }

        ToggleRow {
            first: true
            text: qsTr("Hiện nền")
            checked: GlobalConfig.dock.showBackground
            onToggled: GlobalConfig.dock.showBackground = checked
        }

        ToggleRow {
            text: qsTr("Biểu tượng đơn sắc")
            subtext: qsTr("Tô lại biểu tượng ứng dụng theo một màu duy nhất")
            checked: GlobalConfig.dock.monochromeIcons
            onToggled: GlobalConfig.dock.monochromeIcons = checked
        }

        ToggleRow {
            text: qsTr("Nút ghim")
            subtext: qsTr("Cho phép ghim/bỏ ghim ứng dụng khi rê chuột vào biểu tượng")
            checked: GlobalConfig.dock.showPinButton
            onToggled: GlobalConfig.dock.showPinButton = checked
        }

        ToggleRow {
            text: qsTr("Nút mở Trình khởi chạy")
            checked: GlobalConfig.dock.showAppsButton
            onToggled: GlobalConfig.dock.showAppsButton = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Trình phát nhạc")
            subtext: qsTr("Hiện ảnh bìa của bài đang phát khi có trình phát hoạt động")
            checked: GlobalConfig.dock.showMedia
            onToggled: GlobalConfig.dock.showMedia = checked
        }

        SectionHeader {
            text: qsTr("Ứng dụng")
        }

        TextFieldRow {
            first: true
            label: qsTr("Ứng dụng đã ghim")
            subtext: qsTr("Danh sách id ứng dụng (desktop entry), cách nhau bằng dấu phẩy")
            value: GlobalConfig.dock.pinnedApps.join(", ")
            placeholder: "org.kde.dolphin, kitty"
            onCommitted: value => GlobalConfig.dock.pinnedApps = value.split(",").map(item => item.trim()).filter(item => item)
        }

        TextFieldRow {
            last: true
            label: qsTr("Bỏ qua theo biểu thức chính quy")
            subtext: qsTr("Các cửa sổ có lớp khớp mẫu này sẽ không xuất hiện trong Dock")
            value: GlobalConfig.dock.ignoredAppRegexes.join(", ")
            placeholder: "^kitty-dropdown$"
            onCommitted: value => GlobalConfig.dock.ignoredAppRegexes = value.split(",").map(item => item.trim()).filter(item => item)
        }
    }
}
