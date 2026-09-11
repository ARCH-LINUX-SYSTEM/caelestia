import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property list<MenuItem> positionItems: [
        MenuItem {
            text: qsTr("Trên trái")
        },
        MenuItem {
            text: qsTr("Trên giữa")
        },
        MenuItem {
            text: qsTr("Trên phải")
        },
        MenuItem {
            text: qsTr("Giữa trái")
        },
        MenuItem {
            text: qsTr("Chính giữa")
        },
        MenuItem {
            text: qsTr("Giữa phải")
        },
        MenuItem {
            text: qsTr("Dưới trái")
        },
        MenuItem {
            text: qsTr("Dưới giữa")
        },
        MenuItem {
            text: qsTr("Dưới phải")
        }
    ]
    readonly property list<string> positionValues: ["top-left", "top-center", "top-right", "middle-left", "middle-center", "middle-right", "bottom-left", "bottom-center", "bottom-right"]
    readonly property list<MenuItem> animationItems: [
        MenuItem {
            text: qsTr("Không hiệu ứng")
        },
        MenuItem {
            text: qsTr("Vòng tròn chọn")
        },
        MenuItem {
            text: qsTr("Hố tròn")
        },
        MenuItem {
            text: qsTr("Phép màu")
        },
        MenuItem {
            text: "Doom"
        },
        MenuItem {
            text: "Peel"
        },
        MenuItem {
            text: qsTr("Chuyển cảnh")
        },
        MenuItem {
            text: "Pixelate"
        },
        MenuItem {
            text: qsTr("Sọc")
        },
        MenuItem {
            text: qsTr("Ngẫu nhiên")
        }
    ]
    readonly property list<string> animationValues: ["", "circleSelect", "circlePit", "magic", "Doom", "Peel", "transition", "pixelate", "stripes", "random"]

    function rounded(value: real): real {
        return Math.round(value * 100) / 100;
    }

    function positionIndex(value: string): int {
        return Math.max(0, positionValues.indexOf(value));
    }

    function animationIndex(value: string): int {
        return Math.max(0, animationValues.indexOf(value));
    }

    title: qsTr("Desktop & hiệu ứng nền")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Nền desktop")
        }

        ToggleRow {
            first: true
            text: qsTr("Bật nền Caelestia")
            subtext: qsTr("Hiển thị hình nền, desktop clock và visualiser")
            checked: Config.background.enabled
            onToggled: GlobalConfig.background.enabled = checked
        }

        TextFieldRow {
            label: qsTr("Thư mục hình nền")
            subtext: qsTr("Biến CAELESTIA_WALLPAPERS_DIR vẫn có quyền ưu tiên nếu được đặt")
            value: GlobalConfig.paths.wallpaperDir
            placeholder: "~/Pictures/Wallpapers"
            leadingIcon: "folder"
            emptyIsValid: false
            validate: value => value.trim().length > 0
            onCommitted: value => GlobalConfig.paths.wallpaperDir = value.trim()
        }

        TextFieldRow {
            label: qsTr("Hình nền cố định")
            subtext: qsTr("Ghi đè hình nền hiện tại cho desktop; để trống để dùng dịch vụ Wallpapers")
            value: Config.background.wallpaperPath
            placeholder: "~/Pictures/Wallpapers/image.png"
            leadingIcon: "image"
            onCommitted: value => GlobalConfig.background.wallpaperPath = value.trim()
        }

        TextFieldRow {
            label: qsTr("Ảnh thu nhỏ video")
            subtext: qsTr("Ảnh xem trước tùy chỉnh cho hình nền video")
            value: Config.background.thumbnailPath
            placeholder: "~/Pictures/video-preview.jpg"
            leadingIcon: "preview"
            onCommitted: value => GlobalConfig.background.thumbnailPath = value.trim()
        }

        ToggleRow {
            text: qsTr("Tự phát hình nền video")
            subtext: qsTr("Tắt để chỉ hiển thị khung hình tĩnh đầu tiên, không chạy video ở nền")
            checked: Config.background.videoWallpaperAutoplay
            onToggled: GlobalConfig.background.videoWallpaperAutoplay = checked
        }

        TextFieldRow {
            label: qsTr("Danh sách màn hình")
            subtext: qsTr("Tên màn hình, phân cách bằng dấu phẩy; để trống để dùng mọi màn hình")
            value: Config.background.screenList.join(", ")
            placeholder: "eDP-1, HDMI-A-1"
            leadingIcon: "monitor"
            onCommitted: value => GlobalConfig.background.screenList = value.split(",").map(item => item.trim()).filter(item => item)
        }

        StepperRow {
            label: qsTr("Số hình mỗi hàng")
            subtext: qsTr("Số cột trong trình chọn hình nền Nexus")
            value: GlobalConfig.nexus.wallpapersPerRow
            from: 2
            to: 8
            stepSize: 1
            onMoved: value => GlobalConfig.nexus.wallpapersPerRow = Math.round(value)
        }

        SelectRow {
            last: true
            label: qsTr("Hiệu ứng đổi hình nền")
            menuItems: root.animationItems
            active: root.animationItems[root.animationIndex(Config.background.wallpaperAnimation)]
            onSelected: item => GlobalConfig.background.wallpaperAnimation = root.animationValues[root.animationItems.indexOf(item)]
        }

        SectionHeader {
            text: qsTr("Hình nền căn giữa")
        }

        ToggleRow {
            first: true
            text: qsTr("Dùng hình nền căn giữa")
            subtext: qsTr("Đặt ảnh vuông trên nền màu thay vì phủ toàn màn hình")
            checked: Config.background.centeredWallpaper
            onToggled: GlobalConfig.background.centeredWallpaper = checked
        }

        StepperRow {
            enabled: Config.background.centeredWallpaper
            opacity: enabled ? 1 : 0.55
            label: qsTr("Kích thước")
            value: Config.background.centeredWallpaperSize
            from: 400
            to: 800
            stepSize: 20
            onMoved: value => GlobalConfig.background.centeredWallpaperSize = Math.round(value)
        }

        TextFieldRow {
            enabled: Config.background.centeredWallpaper
            opacity: enabled ? 1 : 0.55
            label: qsTr("Hình dạng")
            subtext: qsTr("Tên MaterialShape được giữ trong config để tương thích")
            value: Config.background.centeredWallpaperShape
            placeholder: "Cookie7Sided"
            leadingIcon: "shapes"
            emptyIsValid: false
            onCommitted: value => GlobalConfig.background.centeredWallpaperShape = value.trim()
        }

        TextFieldRow {
            enabled: Config.background.centeredWallpaper
            opacity: enabled ? 1 : 0.55
            label: qsTr("Màu nền")
            subtext: qsTr("Tên token màu Material, ví dụ primaryContainer")
            value: Config.background.centeredWallpaperColor
            placeholder: "primaryContainer"
            leadingIcon: "format_color_fill"
            emptyIsValid: false
            onCommitted: value => GlobalConfig.background.centeredWallpaperColor = value.trim()
        }

        ToggleRow {
            enabled: Config.background.centeredWallpaper
            opacity: enabled ? 1 : 0.55
            last: true
            text: qsTr("Chỉ căn giữa khi khóa")
            checked: Config.background.centeredWallpaperOnlyWhenLocked
            onToggled: GlobalConfig.background.centeredWallpaperOnlyWhenLocked = checked
        }

        SectionHeader {
            text: qsTr("Đồng hồ desktop")
        }

        ToggleRow {
            first: true
            text: qsTr("Hiển thị đồng hồ")
            checked: Config.background.desktopClock.enabled
            onToggled: GlobalConfig.background.desktopClock.enabled = checked
        }

        StepperRow {
            enabled: Config.background.desktopClock.enabled
            opacity: enabled ? 1 : 0.55
            label: qsTr("Tỷ lệ")
            subtext: qsTr("Kích thước của đồng hồ desktop")
            value: Config.background.desktopClock.scale
            from: 0.5
            to: 2
            stepSize: 0.05
            onMoved: value => GlobalConfig.background.desktopClock.scale = root.rounded(value)
        }

        SelectRow {
            enabled: Config.background.desktopClock.enabled
            opacity: enabled ? 1 : 0.55
            label: qsTr("Vị trí")
            menuItems: root.positionItems
            active: root.positionItems[root.positionIndex(Config.background.desktopClock.position)]
            onSelected: item => GlobalConfig.background.desktopClock.position = root.positionValues[root.positionItems.indexOf(item)]
        }

        ToggleRow {
            enabled: Config.background.desktopClock.enabled
            opacity: enabled ? 1 : 0.55
            text: qsTr("Đảo bộ màu")
            subtext: qsTr("Dùng nhóm màu tương phản với chế độ sáng/tối hiện tại")
            checked: Config.background.desktopClock.invertColors
            onToggled: GlobalConfig.background.desktopClock.invertColors = checked
        }

        ToggleRow {
            enabled: Config.background.desktopClock.enabled
            opacity: enabled ? 1 : 0.55
            text: qsTr("Nền đồng hồ")
            checked: Config.background.desktopClock.background.enabled
            onToggled: GlobalConfig.background.desktopClock.background.enabled = checked
        }

        StepperRow {
            enabled: Config.background.desktopClock.enabled && Config.background.desktopClock.background.enabled
            opacity: enabled ? 1 : 0.55
            label: qsTr("Độ đục nền")
            value: Config.background.desktopClock.background.opacity
            from: 0
            to: 1
            stepSize: 0.05
            onMoved: value => GlobalConfig.background.desktopClock.background.opacity = root.rounded(value)
        }

        ToggleRow {
            enabled: Config.background.desktopClock.enabled && Config.background.desktopClock.background.enabled
            opacity: enabled ? 1 : 0.55
            text: qsTr("Làm mờ phía sau")
            checked: Config.background.desktopClock.background.blur
            onToggled: GlobalConfig.background.desktopClock.background.blur = checked
        }

        ToggleRow {
            enabled: Config.background.desktopClock.enabled
            opacity: enabled ? 1 : 0.55
            text: qsTr("Bóng đổ")
            checked: Config.background.desktopClock.shadow.enabled
            onToggled: GlobalConfig.background.desktopClock.shadow.enabled = checked
        }

        StepperRow {
            enabled: Config.background.desktopClock.enabled && Config.background.desktopClock.shadow.enabled
            opacity: enabled ? 1 : 0.55
            label: qsTr("Độ đục bóng")
            value: Config.background.desktopClock.shadow.opacity
            from: 0
            to: 1
            stepSize: 0.05
            onMoved: value => GlobalConfig.background.desktopClock.shadow.opacity = root.rounded(value)
        }

        StepperRow {
            enabled: Config.background.desktopClock.enabled && Config.background.desktopClock.shadow.enabled
            opacity: enabled ? 1 : 0.55
            last: true
            label: qsTr("Độ mờ bóng")
            value: Config.background.desktopClock.shadow.blur
            from: 0
            to: 1
            stepSize: 0.05
            onMoved: value => GlobalConfig.background.desktopClock.shadow.blur = root.rounded(value)
        }

        SectionHeader {
            text: qsTr("Trực quan hóa âm thanh")
        }

        ToggleRow {
            first: true
            text: qsTr("Hiển thị visualiser")
            checked: Config.background.visualiser.enabled
            onToggled: GlobalConfig.background.visualiser.enabled = checked
        }

        ToggleRow {
            enabled: Config.background.visualiser.enabled
            opacity: enabled ? 1 : 0.55
            text: qsTr("Tự ẩn khi có cửa sổ lát gạch")
            checked: Config.background.visualiser.autoHide
            onToggled: GlobalConfig.background.visualiser.autoHide = checked
        }

        ToggleRow {
            enabled: Config.background.visualiser.enabled
            opacity: enabled ? 1 : 0.55
            text: qsTr("Làm mờ nền visualiser")
            checked: Config.background.visualiser.blur
            onToggled: GlobalConfig.background.visualiser.blur = checked
        }

        StepperRow {
            enabled: Config.background.visualiser.enabled
            opacity: enabled ? 1 : 0.55
            label: qsTr("Tỷ lệ bo góc")
            value: Config.background.visualiser.rounding
            from: 0
            to: 3
            stepSize: 0.1
            onMoved: value => GlobalConfig.background.visualiser.rounding = root.rounded(value)
        }

        StepperRow {
            enabled: Config.background.visualiser.enabled
            opacity: enabled ? 1 : 0.55
            last: true
            label: qsTr("Tỷ lệ khoảng cách")
            value: Config.background.visualiser.spacing
            from: 0
            to: 3
            stepSize: 0.1
            onMoved: value => GlobalConfig.background.visualiser.spacing = root.rounded(value)
        }
    }
}
