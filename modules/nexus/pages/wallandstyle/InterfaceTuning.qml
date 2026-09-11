import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    property int lastWallpaperInterval: GlobalConfig.nexus.wallpaperChangeInterval > 0 ? GlobalConfig.nexus.wallpaperChangeInterval : 30

    readonly property list<MenuItem> screenRoundingItems: [
        MenuItem {
            text: qsTr("Không")
        },
        MenuItem {
            text: qsTr("Luôn bật")
        },
        MenuItem {
            text: qsTr("Khi không toàn màn hình")
        }
    ]
    readonly property list<int> screenRoundingValues: [0, 1, 2]
    readonly property list<MenuItem> paletteItems: [
        MenuItem {
            text: qsTr("Tự động")
        },
        MenuItem {
            text: qsTr("Theo nội dung")
        },
        MenuItem {
            text: qsTr("Biểu cảm")
        },
        MenuItem {
            text: qsTr("Trung thực")
        },
        MenuItem {
            text: qsTr("Salad trái cây")
        },
        MenuItem {
            text: qsTr("Đơn sắc")
        },
        MenuItem {
            text: qsTr("Trung tính")
        },
        MenuItem {
            text: qsTr("Cầu vồng")
        },
        MenuItem {
            text: qsTr("Điểm tông màu")
        }
    ]
    readonly property list<string> paletteValues: [
        "auto",
        "scheme-content",
        "scheme-expressive",
        "scheme-fidelity",
        "scheme-fruit-salad",
        "scheme-monochrome",
        "scheme-neutral",
        "scheme-rainbow",
        "scheme-tonal-spot"
    ]

    function rounded(value: real): real {
        return Math.round(value * 100) / 100;
    }

    function selected(items: var, values: var, value: var): var {
        const index = values.indexOf(value);
        return items[Math.max(0, index)];
    }

    title: qsTr("Tinh chỉnh giao diện")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Tỷ lệ giao diện")
        }

        StepperRow {
            first: true
            label: qsTr("Bo góc")
            subtext: qsTr("Tỷ lệ bo góc của component Caelestia")
            value: Config.appearance.rounding.scale
            from: 0
            to: 2
            stepSize: 0.05
            onMoved: value => GlobalConfig.appearance.rounding.scale = root.rounded(value)
        }

        StepperRow {
            label: qsTr("Khoảng cách")
            subtext: qsTr("Tỷ lệ khoảng cách giữa các thành phần")
            value: Config.appearance.spacing.scale
            from: 0.5
            to: 2
            stepSize: 0.05
            onMoved: value => GlobalConfig.appearance.spacing.scale = root.rounded(value)
        }

        StepperRow {
            label: qsTr("Phần đệm")
            subtext: qsTr("Tỷ lệ phần đệm bên trong component")
            value: Config.appearance.padding.scale
            from: 0.5
            to: 2
            stepSize: 0.05
            onMoved: value => GlobalConfig.appearance.padding.scale = root.rounded(value)
        }

        StepperRow {
            label: qsTr("Phông chữ")
            subtext: qsTr("Tỷ lệ phông chữ trong toàn bộ shell")
            value: Config.appearance.font.scale
            from: 0.75
            to: 1.75
            stepSize: 0.05
            onMoved: value => GlobalConfig.appearance.font.scale = root.rounded(value)
        }

        StepperRow {
            label: qsTr("Thời lượng hiệu ứng")
            subtext: qsTr("0 tắt chuyển tiếp; giá trị lớn hơn làm hiệu ứng chậm hơn")
            value: GlobalConfig.appearance.anim.durations.scale
            from: 0
            to: 3
            stepSize: 0.1
            onMoved: value => GlobalConfig.appearance.anim.durations.scale = root.rounded(value)
        }

        StepperRow {
            last: true
            label: qsTr("Biến dạng khi kéo")
            subtext: qsTr("Cường độ hiệu ứng biến dạng của drawer")
            value: Config.appearance.deformScale
            from: 0
            to: 2
            stepSize: 0.1
            onMoved: value => GlobalConfig.appearance.deformScale = root.rounded(value)
        }

        SectionHeader {
            text: qsTr("Độ trong suốt")
        }

        ToggleRow {
            first: true
            text: qsTr("Bật độ trong suốt")
            checked: GlobalConfig.appearance.transparency.enabled
            onToggled: GlobalConfig.appearance.transparency.enabled = checked
        }

        ToggleRow {
            enabled: GlobalConfig.appearance.transparency.enabled
            opacity: enabled ? 1 : 0.55
            text: qsTr("Tự điều chỉnh theo hình nền")
            subtext: qsTr("Tính độ đục an toàn từ độ sáng của hình nền hiện tại")
            checked: GlobalConfig.appearance.transparency.automatic
            onToggled: GlobalConfig.appearance.transparency.automatic = checked
        }

        StepperRow {
            enabled: GlobalConfig.appearance.transparency.enabled && !GlobalConfig.appearance.transparency.automatic
            opacity: enabled ? 1 : 0.55
            label: qsTr("Nền cơ sở")
            subtext: GlobalConfig.appearance.transparency.automatic ? qsTr("Đang tự động: %1").arg(root.rounded(Colours.transparency.base)) : qsTr("Độ đục của lớp nền chính")
            value: GlobalConfig.appearance.transparency.base
            from: 0
            to: 1
            stepSize: 0.05
            onMoved: value => GlobalConfig.appearance.transparency.base = root.rounded(value)
        }

        StepperRow {
            enabled: GlobalConfig.appearance.transparency.enabled && !GlobalConfig.appearance.transparency.automatic
            opacity: enabled ? 1 : 0.55
            last: true
            label: qsTr("Các lớp nội dung")
            subtext: qsTr("Độ đục của card, popup và thành phần nổi")
            value: GlobalConfig.appearance.transparency.layers
            from: 0
            to: 1
            stepSize: 0.05
            onMoved: value => GlobalConfig.appearance.transparency.layers = root.rounded(value)
        }

        SectionHeader {
            text: qsTr("Viền shell")
        }

        StepperRow {
            first: true
            label: qsTr("Độ dày")
            subtext: qsTr("Độ dày vùng viền và cạnh tương tác")
            value: Config.border.thickness
            from: 2
            to: 40
            stepSize: 1
            onMoved: value => GlobalConfig.border.thickness = Math.round(value)
        }

        StepperRow {
            label: qsTr("Bo góc")
            subtext: qsTr("Bán kính bo góc cơ sở của shell")
            value: Config.border.rounding
            from: 0
            to: 100
            stepSize: 1
            onMoved: value => GlobalConfig.border.rounding = Math.round(value)
        }

        SelectRow {
            label: qsTr("Bo góc màn hình giả")
            subtext: qsTr("Dùng chính viền SDF của Caelestia; không tạo lớp giao diện end4")
            menuItems: root.screenRoundingItems
            active: root.selected(root.screenRoundingItems, root.screenRoundingValues, Config.appearance.fakeScreenRounding)
            onSelected: item => GlobalConfig.appearance.fakeScreenRounding = root.screenRoundingValues[root.screenRoundingItems.indexOf(item)]
        }

        StepperRow {
            last: true
            label: qsTr("Làm mượt")
            subtext: qsTr("Mức làm mượt hình dạng ở cạnh màn hình")
            value: Config.border.smoothing
            from: 0
            to: 100
            stepSize: 1
            onMoved: value => GlobalConfig.border.smoothing = Math.round(value)
        }

        SectionHeader {
            text: qsTr("Phông chữ theo vai trò")
        }

        TextFieldRow {
            first: true
            label: qsTr("Nội dung chính")
            subtext: qsTr("Áp dụng cho body và label của Caelestia")
            value: GlobalConfig.appearance.font.body.family
            placeholder: "GoogleSansFlex"
            leadingIcon: "font_download"
            emptyIsValid: false
            onCommitted: value => {
                const family = value.trim();
                GlobalConfig.appearance.font.body.family = family;
                GlobalConfig.appearance.font.label.family = family;
            }
        }

        TextFieldRow {
            label: qsTr("Tiêu đề")
            subtext: qsTr("Áp dụng cho title và headline")
            value: GlobalConfig.appearance.font.title.family
            placeholder: "GoogleSansFlex"
            leadingIcon: "title"
            emptyIsValid: false
            onCommitted: value => {
                const family = value.trim();
                GlobalConfig.appearance.font.title.family = family;
                GlobalConfig.appearance.font.headline.family = family;
            }
        }

        TextFieldRow {
            label: qsTr("Số")
            subtext: qsTr("Vai trò tương thích cho số liệu và chỉ số")
            value: GlobalConfig.appearance.font.numbers
            placeholder: "Google Sans Flex"
            leadingIcon: "123"
            emptyIsValid: false
            onCommitted: value => GlobalConfig.appearance.font.numbers = value.trim()
        }

        TextFieldRow {
            label: qsTr("Monospace")
            subtext: qsTr("Dùng cho mã, địa chỉ và dữ liệu độ rộng cố định")
            value: GlobalConfig.appearance.font.mono.family
            placeholder: "CaskaydiaCove NF"
            leadingIcon: "code"
            emptyIsValid: false
            onCommitted: value => GlobalConfig.appearance.font.mono.family = value.trim()
        }

        TextFieldRow {
            label: qsTr("Nerd Font cho workspace")
            value: GlobalConfig.appearance.font.workspaces
            placeholder: "Rubik"
            leadingIcon: "grid_view"
            emptyIsValid: false
            onCommitted: value => GlobalConfig.appearance.font.workspaces = value.trim()
        }

        TextFieldRow {
            label: qsTr("Đọc nội dung dài")
            value: GlobalConfig.appearance.font.reading
            placeholder: "Readex Pro"
            leadingIcon: "menu_book"
            emptyIsValid: false
            onCommitted: value => GlobalConfig.appearance.font.reading = value.trim()
        }

        TextFieldRow {
            last: true
            label: qsTr("Biểu cảm")
            subtext: qsTr("Vai trò tùy chọn cho overview và desktop")
            value: GlobalConfig.appearance.font.expressive
            placeholder: "Space Grotesk"
            leadingIcon: "draw"
            emptyIsValid: false
            onCommitted: value => GlobalConfig.appearance.font.expressive = value.trim()
        }

        SectionHeader {
            text: qsTr("Palette")
        }

        SelectRow {
            first: true
            label: qsTr("Kiểu sinh màu")
            subtext: qsTr("Áp dụng qua công cụ scheme hiện có của Caelestia")
            menuItems: root.paletteItems
            active: root.selected(root.paletteItems, root.paletteValues, GlobalConfig.appearance.palette.type)
            onSelected: item => GlobalConfig.appearance.palette.type = root.paletteValues[root.paletteItems.indexOf(item)]
        }

        TextFieldRow {
            label: qsTr("Màu nhấn tùy chỉnh")
            subtext: qsTr("Ghi đè màu primary bên trong shell; để trống để dùng màu sinh tự động")
            value: GlobalConfig.appearance.palette.accentColor
            placeholder: "#AABBCC"
            leadingIcon: "colorize"
            validate: /^(|#[0-9A-Fa-f]{6}(?:[0-9A-Fa-f]{2})?)$/
            onCommitted: value => GlobalConfig.appearance.palette.accentColor = value.trim()
        }

        ToggleRow {
            last: true
            text: qsTr("Thêm sắc màu nhẹ cho nền")
            subtext: qsTr("Pha 1% màu primary vào lớp nền gốc")
            checked: GlobalConfig.appearance.extraBackgroundTint
            onToggled: GlobalConfig.appearance.extraBackgroundTint = checked
        }

        SectionHeader {
            text: qsTr("Theme hình nền bên ngoài shell")
        }

        ToggleRow {
            first: true
            text: qsTr("Cho Caelestia quản lý cầu nối theme")
            subtext: qsTr("Tắt mặc định để không ghi đè ~/.config/caelestia/cli.json")
            checked: GlobalConfig.appearance.wallpaperTheming.managed
            onToggled: GlobalConfig.appearance.wallpaperTheming.managed = checked
        }

        ToggleRow {
            enabled: GlobalConfig.appearance.wallpaperTheming.managed
            opacity: enabled ? 1 : 0.55
            text: qsTr("Shell, Hyprland và ứng dụng GTK")
            checked: GlobalConfig.appearance.wallpaperTheming.enableAppsAndShell
            onToggled: GlobalConfig.appearance.wallpaperTheming.enableAppsAndShell = checked
        }

        ToggleRow {
            enabled: GlobalConfig.appearance.wallpaperTheming.managed
            opacity: enabled ? 1 : 0.55
            text: qsTr("Ứng dụng Qt")
            checked: GlobalConfig.appearance.wallpaperTheming.enableQtApps
            onToggled: GlobalConfig.appearance.wallpaperTheming.enableQtApps = checked
        }

        ToggleRow {
            enabled: GlobalConfig.appearance.wallpaperTheming.managed
            opacity: enabled ? 1 : 0.55
            text: qsTr("Terminal")
            checked: GlobalConfig.appearance.wallpaperTheming.enableTerminal
            onToggled: GlobalConfig.appearance.wallpaperTheming.enableTerminal = checked
        }

        ToggleRow {
            enabled: GlobalConfig.appearance.wallpaperTheming.managed && GlobalConfig.appearance.wallpaperTheming.enableTerminal
            opacity: enabled ? 1 : 0.55
            text: qsTr("Ép terminal dùng nền tối")
            checked: GlobalConfig.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode
            onToggled: GlobalConfig.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode = checked
        }

        StepperRow {
            enabled: GlobalConfig.appearance.wallpaperTheming.managed && GlobalConfig.appearance.wallpaperTheming.enableTerminal
            opacity: enabled ? 1 : 0.55
            label: qsTr("Độ hòa sắc terminal")
            value: GlobalConfig.appearance.wallpaperTheming.terminalGenerationProps.harmony
            from: 0
            to: 1
            stepSize: 0.05
            onMoved: value => GlobalConfig.appearance.wallpaperTheming.terminalGenerationProps.harmony = root.rounded(value)
        }

        StepperRow {
            enabled: GlobalConfig.appearance.wallpaperTheming.managed && GlobalConfig.appearance.wallpaperTheming.enableTerminal
            opacity: enabled ? 1 : 0.55
            label: qsTr("Ngưỡng xoay sắc độ")
            value: GlobalConfig.appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold
            from: 0
            to: 100
            stepSize: 5
            onMoved: value => GlobalConfig.appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold = Math.round(value)
        }

        StepperRow {
            enabled: GlobalConfig.appearance.wallpaperTheming.managed && GlobalConfig.appearance.wallpaperTheming.enableTerminal
            opacity: enabled ? 1 : 0.55
            last: true
            label: qsTr("Tăng tương phản chữ terminal")
            value: GlobalConfig.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost
            from: 0
            to: 1
            stepSize: 0.05
            onMoved: value => GlobalConfig.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost = root.rounded(value)
        }

        SectionHeader {
            text: qsTr("Tự động đổi hình nền")
        }

        ToggleRow {
            first: true
            text: qsTr("Tự động đổi hình nền")
            subtext: qsTr("Định kỳ chuyển sang một hình nền ngẫu nhiên khác trong bộ sưu tập")
            checked: GlobalConfig.nexus.wallpaperChangeInterval > 0
            onToggled: {
                if (checked)
                    GlobalConfig.nexus.wallpaperChangeInterval = root.lastWallpaperInterval > 0 ? root.lastWallpaperInterval : 30;
                else {
                    if (GlobalConfig.nexus.wallpaperChangeInterval > 0)
                        root.lastWallpaperInterval = GlobalConfig.nexus.wallpaperChangeInterval;
                    GlobalConfig.nexus.wallpaperChangeInterval = 0;
                }
            }
        }

        StepperRow {
            enabled: GlobalConfig.nexus.wallpaperChangeInterval > 0
            opacity: enabled ? 1 : 0.55
            label: qsTr("Thời gian đổi")
            subtext: qsTr("Khoảng cách giữa mỗi lần đổi hình nền ngẫu nhiên, tính bằng phút")
            value: GlobalConfig.nexus.wallpaperChangeInterval > 0 ? GlobalConfig.nexus.wallpaperChangeInterval : root.lastWallpaperInterval
            from: 1
            to: 1440
            stepSize: 1
            onMoved: value => {
                const rounded = Math.round(value);
                root.lastWallpaperInterval = rounded;
                if (GlobalConfig.nexus.wallpaperChangeInterval > 0)
                    GlobalConfig.nexus.wallpaperChangeInterval = rounded;
            }
        }

        InfoRow {
            last: true
            label: qsTr("Kiểu hình nền hiện tại")
            subtext: qsTr("Tự động nhận diện theo đuôi tệp: video (.mp4, .webm, .mkv) sẽ phát như video; ảnh tĩnh (.png, .jpg, .jpeg, .webp, ...) hiển thị như ảnh nền")
            value: Wallpapers.isVideo(Wallpapers.current) ? qsTr("Video") : qsTr("Ảnh tĩnh")
        }
    }
}
