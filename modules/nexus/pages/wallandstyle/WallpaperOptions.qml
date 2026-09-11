import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Trình chọn hình nền nâng cao")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Cửa sổ chọn tệp")
        }

        ToggleRow {
            first: true
            text: qsTr("Dùng hộp thoại tệp của hệ thống")
            subtext: qsTr("Mở trình chọn tệp native qua Qt thay cho cửa sổ Caelestia")
            checked: GlobalConfig.nexus.useSystemFileDialog
            onToggled: GlobalConfig.nexus.useSystemFileDialog = checked
        }

        ToggleRow {
            text: qsTr("Hiển thị đường dẫn Trang chủ")
            subtext: qsTr("Dùng thư mục người dùng làm vị trí bắt đầu khi không có đường dẫn riêng")
            checked: GlobalConfig.nexus.showWallpaperHomePath
            onToggled: GlobalConfig.nexus.showWallpaperHomePath = checked
        }

        TextFieldRow {
            last: true
            label: qsTr("Đường dẫn nhanh tùy chỉnh")
            subtext: qsTr("Để trống để dùng Trang chủ hoặc thư mục hình nền hiện tại")
            value: GlobalConfig.nexus.wallpaperUserPath
            placeholder: "~/Pictures/Wallpapers"
            leadingIcon: "folder_shortcut"
            onCommitted: value => GlobalConfig.nexus.wallpaperUserPath = value.trim()
        }

        SectionHeader {
            text: qsTr("Hiển thị")
        }

        ToggleRow {
            first: true
            text: qsTr("Nền hình ảnh làm mờ")
            subtext: qsTr("Hiển thị hình nền hiện tại phía sau danh sách")
            checked: GlobalConfig.nexus.showWallpaperBlurBackground
            onToggled: GlobalConfig.nexus.showWallpaperBlurBackground = checked
        }

        ToggleRow {
            text: qsTr("Thanh tìm kiếm")
            subtext: qsTr("Lọc hình nền và danh mục theo tên")
            checked: GlobalConfig.nexus.showWallpaperSearch
            onToggled: GlobalConfig.nexus.showWallpaperSearch = checked
        }

        StepperRow {
            last: true
            label: qsTr("Số cột")
            subtext: qsTr("Số hình nền hiển thị trên mỗi hàng")
            value: GlobalConfig.nexus.wallpapersPerRow
            from: 3
            to: 10
            stepSize: 1
            onMoved: value => GlobalConfig.nexus.wallpapersPerRow = Math.round(value)
        }

        SectionHeader {
            text: qsTr("Hành vi")
        }

        ToggleRow {
            first: true
            text: qsTr("Đóng sau khi chọn")
            subtext: qsTr("Quay lại trang trước ngay sau khi đặt hình nền")
            checked: GlobalConfig.nexus.closeAfterWallpaperSelection
            onToggled: GlobalConfig.nexus.closeAfterWallpaperSelection = checked
        }

        StepperRow {
            last: true
            label: qsTr("Tự đổi hình nền")
            subtext: GlobalConfig.nexus.wallpaperChangeInterval === 0 ? qsTr("Đang tắt • đơn vị phút") : qsTr("%1 phút").arg(GlobalConfig.nexus.wallpaperChangeInterval)
            value: GlobalConfig.nexus.wallpaperChangeInterval
            from: 0
            to: 1440
            stepSize: 1
            onMoved: value => GlobalConfig.nexus.wallpaperChangeInterval = Math.round(value)
        }
    }
}
