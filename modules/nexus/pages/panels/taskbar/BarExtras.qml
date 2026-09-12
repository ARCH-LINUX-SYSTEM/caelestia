pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property list<MenuItem> resourceStyleItems: [
        MenuItem {
            text: qsTr("Đầy")
        },
        MenuItem {
            text: qsTr("Viền")
        }
    ]
    readonly property list<string> resourceStyleValues: ["filled", "outline"]
    readonly property list<MenuItem> groupStyleItems: [
        MenuItem {
            text: qsTr("Trong suốt")
        },
        MenuItem {
            text: qsTr("Dạng viên")
        },
        MenuItem {
            text: qsTr("Tách rời")
        }
    ]
    readonly property list<string> groupStyleValues: ["transparent", "pills", "separated"]

    function selectedItem(items: var, values: var, value: string): var {
        return items[Math.max(0, values.indexOf(value))];
    }

    title: qsTr("Tùy chọn thanh tác vụ mở rộng")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Tự động ẩn")
        }

        ToggleRow {
            first: true
            text: qsTr("Tự động ẩn")
            subtext: qsTr("Dùng hành vi tự ẩn được viết lại cho thanh dọc Caelestia")
            checked: Config.bar.autoHide.enable
            onToggled: GlobalConfig.bar.autoHide.enable = checked
        }

        ToggleRow {
            enabled: Config.bar.autoHide.enable
            opacity: enabled ? 1 : 0.55
            text: qsTr("Đẩy cửa sổ khi hiện")
            subtext: qsTr("Dành vùng độc quyền cho thanh trong lúc thanh đang mở")
            checked: Config.bar.autoHide.pushWindows
            onToggled: GlobalConfig.bar.autoHide.pushWindows = checked
        }

        StepperRow {
            enabled: Config.bar.autoHide.enable
            opacity: enabled ? 1 : 0.55
            label: qsTr("Bề rộng vùng rê")
            subtext: qsTr("Kích thước vùng kích hoạt ở cạnh trái (px)")
            value: Config.bar.autoHide.hoverRegionWidth
            from: 0
            to: 100
            stepSize: 1
            onMoved: value => GlobalConfig.bar.autoHide.hoverRegionWidth = Math.round(value)
        }

        ToggleRow {
            enabled: Config.bar.autoHide.enable
            opacity: enabled ? 1 : 0.55
            text: qsTr("Hiện khi giữ phím Super")
            subtext: qsTr("Lưu cấu hình tương thích; cần compositor chuyển trạng thái Super cho shell")
            checked: Config.bar.autoHide.showWhenPressingSuper.enable
            onToggled: GlobalConfig.bar.autoHide.showWhenPressingSuper.enable = checked
        }

        StepperRow {
            last: true
            enabled: Config.bar.autoHide.enable && Config.bar.autoHide.showWhenPressingSuper.enable
            opacity: enabled ? 1 : 0.55
            label: qsTr("Độ trễ phím Super")
            value: Config.bar.autoHide.showWhenPressingSuper.delay
            from: 0
            to: 5000
            stepSize: 10
            onMoved: value => GlobalConfig.bar.autoHide.showWhenPressingSuper.delay = Math.round(value)
        }

        SectionHeader {
            text: qsTr("Kiểu dáng tương thích")
        }

        ToggleRow {
            first: true
            text: qsTr("Hiện nền thanh")
            checked: Config.bar.showBackground
            onToggled: GlobalConfig.bar.showBackground = checked
        }

        ToggleRow {
            text: qsTr("Chế độ chi tiết")
            subtext: qsTr("Cho phép component hỗ trợ hiển thị thêm nội dung")
            checked: Config.bar.verbose
            onToggled: GlobalConfig.bar.verbose = checked
        }

        TextFieldRow {
            label: qsTr("Biểu tượng đầu thanh")
            subtext: qsTr("`spark`, `distro` hoặc tên Material icon")
            value: Config.bar.topLeftIcon
            placeholder: "spark"
            onCommitted: value => GlobalConfig.bar.topLeftIcon = value
        }

        SelectRow {
            last: true
            label: qsTr("Kiểu nhóm")
            subtext: qsTr("Được các component Caelestia có hỗ trợ sử dụng")
            menuItems: root.groupStyleItems
            active: root.selectedItem(root.groupStyleItems, root.groupStyleValues, Config.bar.borderless)
            onSelected: item => GlobalConfig.bar.borderless = root.groupStyleValues[root.groupStyleItems.indexOf(item)]
        }

        SectionHeader {
            text: qsTr("Tài nguyên")
        }

        SelectRow {
            first: true
            label: qsTr("Kiểu chỉ báo")
            menuItems: root.resourceStyleItems
            active: root.selectedItem(root.resourceStyleItems, root.resourceStyleValues, Config.bar.resources.style)
            onSelected: item => GlobalConfig.bar.resources.style = root.resourceStyleValues[root.resourceStyleItems.indexOf(item)]
        }

        ToggleRow {
            text: qsTr("Hiện giá trị")
            checked: Config.bar.resources.showValue
            onToggled: GlobalConfig.bar.resources.showValue = checked
        }

        ToggleRow {
            text: "CPU"
            checked: Config.bar.resources.alwaysShowCpu
            onToggled: GlobalConfig.bar.resources.alwaysShowCpu = checked
        }

        ToggleRow {
            text: qsTr("Nhiệt độ CPU")
            checked: Config.bar.resources.alwaysShowCpuTemp
            onToggled: GlobalConfig.bar.resources.alwaysShowCpuTemp = checked
        }

        ToggleRow {
            text: "RAM"
            checked: Config.bar.resources.alwaysShowRam
            onToggled: GlobalConfig.bar.resources.alwaysShowRam = checked
        }

        ToggleRow {
            text: qsTr("Ổ đĩa")
            checked: Config.bar.resources.alwaysShowDisk
            onToggled: GlobalConfig.bar.resources.alwaysShowDisk = checked
        }

        ToggleRow {
            text: "Swap"
            checked: Config.bar.resources.alwaysShowSwap
            onToggled: GlobalConfig.bar.resources.alwaysShowSwap = checked
        }

        StepperRow {
            label: qsTr("Cảnh báo CPU")
            value: Config.bar.resources.cpuWarningThreshold
            from: 0
            to: 100
            stepSize: 1
            onMoved: value => GlobalConfig.bar.resources.cpuWarningThreshold = Math.round(value)
        }

        StepperRow {
            label: qsTr("Cảnh báo RAM")
            value: Config.bar.resources.memoryWarningThreshold
            from: 0
            to: 100
            stepSize: 1
            onMoved: value => GlobalConfig.bar.resources.memoryWarningThreshold = Math.round(value)
        }

        StepperRow {
            last: true
            label: qsTr("Cảnh báo Swap")
            value: Config.bar.resources.swapWarningThreshold
            from: 0
            to: 100
            stepSize: 1
            onMoved: value => GlobalConfig.bar.resources.swapWarningThreshold = Math.round(value)
        }

        SectionHeader {
            text: qsTr("Nút tiện ích")
        }

        ToggleRow {
            first: true
            text: qsTr("Chụp vùng màn hình")
            checked: Config.bar.utilButtons.showScreenSnip
            onToggled: GlobalConfig.bar.utilButtons.showScreenSnip = checked
        }

        ToggleRow {
            text: qsTr("Chọn màu")
            checked: Config.bar.utilButtons.showColorPicker
            onToggled: GlobalConfig.bar.utilButtons.showColorPicker = checked
        }

        ToggleRow {
            text: qsTr("Bật/tắt micrô")
            checked: Config.bar.utilButtons.showMicToggle
            onToggled: GlobalConfig.bar.utilButtons.showMicToggle = checked
        }

        ToggleRow {
            text: qsTr("Bàn phím ảo")
            checked: Config.bar.utilButtons.showKeyboardToggle
            onToggled: GlobalConfig.bar.utilButtons.showKeyboardToggle = checked
        }

        ToggleRow {
            text: qsTr("Đổi hình nền")
            checked: Config.bar.utilButtons.showWallpaperToggle
            onToggled: GlobalConfig.bar.utilButtons.showWallpaperToggle = checked
        }

        ToggleRow {
            text: qsTr("Chế độ sáng/tối")
            checked: Config.bar.utilButtons.showDarkModeToggle
            onToggled: GlobalConfig.bar.utilButtons.showDarkModeToggle = checked
        }

        ToggleRow {
            text: qsTr("Hồ sơ hiệu năng")
            checked: Config.bar.utilButtons.showPerformanceProfileToggle
            onToggled: GlobalConfig.bar.utilButtons.showPerformanceProfileToggle = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Ghi màn hình")
            checked: Config.bar.utilButtons.showScreenRecord
            onToggled: GlobalConfig.bar.utilButtons.showScreenRecord = checked
        }

        SectionHeader {
            text: qsTr("Thời tiết")
        }

        ToggleRow {
            first: true
            text: qsTr("Bật thành phần thời tiết")
            checked: Config.bar.weather.enable
            onToggled: GlobalConfig.bar.weather.enable = checked
        }

        ToggleRow {
            enabled: Config.bar.weather.enable
            opacity: enabled ? 1 : 0.55
            text: qsTr("Tự tìm vị trí")
            checked: Config.bar.weather.enableGPS
            onToggled: GlobalConfig.bar.weather.enableGPS = checked
        }

        TextFieldRow {
            enabled: Config.bar.weather.enable && !Config.bar.weather.enableGPS
            opacity: enabled ? 1 : 0.55
            label: qsTr("Thành phố")
            value: Config.bar.weather.city
            placeholder: qsTr("Ví dụ: Hà Nội")
            onCommitted: value => GlobalConfig.bar.weather.city = value
        }

        ToggleRow {
            enabled: Config.bar.weather.enable
            opacity: enabled ? 1 : 0.55
            text: qsTr("Dùng đơn vị Hoa Kỳ")
            checked: Config.bar.weather.useUSCS
            onToggled: GlobalConfig.bar.weather.useUSCS = checked
        }

        StepperRow {
            last: true
            enabled: Config.bar.weather.enable
            opacity: enabled ? 1 : 0.55
            label: qsTr("Chu kỳ cập nhật")
            subtext: qsTr("Phút")
            value: Config.bar.weather.fetchInterval
            from: 5
            to: 1440
            stepSize: 5
            onMoved: value => GlobalConfig.bar.weather.fetchInterval = Math.round(value)
        }

        SectionHeader {
            text: qsTr("Media và chỉ báo")
        }

        TextFieldRow {
            first: true
            label: qsTr("Trình phát ưu tiên")
            subtext: qsTr("Để trống để dùng lựa chọn trong Dịch vụ")
            value: Config.bar.media.preferredPlayer
            placeholder: qsTr("Tự động")
            onCommitted: value => GlobalConfig.bar.media.preferredPlayer = value
        }

        ToggleRow {
            text: qsTr("Luôn hiện media")
            checked: Config.bar.media.alwaysVisible
            onToggled: GlobalConfig.bar.media.alwaysVisible = checked
        }

        ToggleRow {
            text: qsTr("Chỉ hiện tiêu đề")
            checked: Config.bar.media.onlyTitle
            onToggled: GlobalConfig.bar.media.onlyTitle = checked
        }

        ToggleRow {
            text: qsTr("Hiện số thông báo chưa đọc")
            checked: Config.bar.indicators.notifications.showUnreadCount
            onToggled: GlobalConfig.bar.indicators.notifications.showUnreadCount = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Nhấn để hiện tooltip")
            checked: Config.bar.tooltips.clickToShow
            onToggled: GlobalConfig.bar.tooltips.clickToShow = checked
        }
    }
}
