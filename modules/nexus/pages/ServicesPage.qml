import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.Services
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    // Lyrics backends, ordered to match LyricsBackend::Backend (Auto, Local, LRCLIB, NetEase)
    readonly property list<MenuItem> lyricsItems: [
        MenuItem {
            text: qsTr("Tự động")
        },
        MenuItem {
            text: "Local"
        },
        MenuItem {
            text: "LRCLIB"
        },
        MenuItem {
            text: "NetEase"
        }
    ]

    // GPU options + the config string each maps to (see Gpu::parseType)
    readonly property list<MenuItem> gpuItems: [
        MenuItem {
            text: qsTr("Tự động")
        },
        MenuItem {
            text: "NVIDIA"
        },
        MenuItem {
            text: qsTr("Phổ thông")
        },
        MenuItem {
            text: qsTr("Không có")
        }
    ]
    readonly property list<string> gpuValues: ["", "NVIDIA", "GENERIC", "None"]

    function gpuKeyToIndex(key: string): int {
        const u = (key ?? "").trim().toUpperCase();
        if (u === "")
            return 0; // Auto
        if (u === "NVIDIA")
            return 1;
        if (u === "GENERIC")
            return 2;
        return 3; // None
    }

    title: qsTr("Dịch vụ")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Detected running players, used as default-player options
        Variants {
            id: playerVariants

            model: [...new Set(Players.list.map(p => Players.getIdentity(p)).filter(id => id))]

            MenuItem {
                required property string modelData

                text: modelData
                icon: modelData === GlobalConfig.services.defaultPlayer ? "check" : ""
                activeIcon: "music_note"
            }
        }

        // Notifications
        SectionHeader {
            first: true
            text: qsTr("Thông báo")
        }

        NavRow {
            first: true
            last: true
            icon: "notifications"
            label: qsTr("Thông báo")
            status: qsTr("Thông báo, thông báo nổi, thời gian chờ")
            onClicked: root.nState.openSubPage(1)
        }

        // Polling
        SectionHeader {
            text: qsTr("Cập nhật định kỳ")
        }

        StepperRow {
            first: true
            label: qsTr("Cập nhật phương tiện")
            subtext: qsTr("Chu kỳ cập nhật vị trí phát (ms)")
            value: GlobalConfig.dashboard.mediaUpdateInterval
            from: 100
            to: 2000
            stepSize: 50
            onMoved: v => GlobalConfig.dashboard.mediaUpdateInterval = v
        }

        StepperRow {
            label: qsTr("Cập nhật thống kê hệ thống")
            subtext: qsTr("Chu kỳ cập nhật CPU, bộ nhớ và GPU (giây)")
            value: GlobalConfig.dashboard.resourceUpdateInterval / 1000
            from: 0.5
            to: 10
            stepSize: 0.5
            onMoved: v => GlobalConfig.dashboard.resourceUpdateInterval = Math.round(v * 1000)
        }

        StepperRow {
            last: true
            label: qsTr("Quét lại Wi-Fi")
            subtext: qsTr("Chu kỳ quét lại mạng khả dụng (giây)")
            value: GlobalConfig.nexus.networkRescanInterval / 1000
            from: 5
            to: 120
            stepSize: 5
            onMoved: v => GlobalConfig.nexus.networkRescanInterval = Math.round(v * 1000)
        }

        SectionHeader {
            text: qsTr("Mạng dịch vụ")
        }

        TextFieldRow {
            first: true
            last: true
            label: "User-Agent"
            subtext: qsTr("Được gửi bởi các yêu cầu thời tiết và định vị của shell")
            value: GlobalConfig.services.networkUserAgent
            placeholder: "Mozilla/5.0 ..."
            leadingIcon: "language"
            onCommitted: value => GlobalConfig.services.networkUserAgent = value.trim()
        }

        SectionHeader {
            text: qsTr("Tìm kiếm")
        }

        ToggleRow {
            first: true
            text: qsTr("Tìm gần đúng kiểu Levenshtein")
            subtext: qsTr("Chịu lỗi gõ sai tốt hơn thay cho thuật toán tìm hiện tại")
            checked: GlobalConfig.search.sloppy
            onToggled: GlobalConfig.search.sloppy = checked
        }

        ToggleRow {
            text: qsTr("Hiện action mặc định không cần tiền tố")
            subtext: qsTr("Thêm “Tìm trên web” và “Chạy lệnh” vào kết quả ứng dụng")
            checked: GlobalConfig.search.prefix.showDefaultActionsWithoutPrefix
            onToggled: GlobalConfig.search.prefix.showDefaultActionsWithoutPrefix = checked
        }

        StepperRow {
            label: qsTr("Độ trễ kết quả không phải ứng dụng")
            subtext: qsTr("Tránh giật khi nhập nhanh (ms)")
            value: GlobalConfig.search.nonAppResultDelay
            from: 0
            to: 1000
            stepSize: 10
            onMoved: value => GlobalConfig.search.nonAppResultDelay = Math.round(value)
        }

        TextFieldRow {
            label: qsTr("Tiền tố action")
            value: GlobalConfig.launcher.actionPrefix
            placeholder: ">"
            leadingIcon: "bolt"
            validate: /^\S{0,8}$/
            onCommitted: value => GlobalConfig.launcher.actionPrefix = value
        }

        TextFieldRow {
            label: qsTr("Tiền tố ứng dụng")
            subtext: qsTr("Để trống để tìm ứng dụng trực tiếp như Caelestia mặc định")
            value: GlobalConfig.launcher.appPrefix
            placeholder: ""
            leadingIcon: "apps"
            validate: /^\S{0,8}$/
            onCommitted: value => GlobalConfig.launcher.appPrefix = value
        }

        TextFieldRow {
            label: qsTr("Tiền tố lệnh shell")
            value: GlobalConfig.search.prefix.shellCommand
            placeholder: "$"
            leadingIcon: "terminal"
            validate: /^\S{0,8}$/
            onCommitted: value => GlobalConfig.search.prefix.shellCommand = value
        }

        TextFieldRow {
            label: qsTr("Tiền tố tìm web")
            value: GlobalConfig.search.prefix.webSearch
            placeholder: "?"
            leadingIcon: "travel_explore"
            validate: /^\S{0,8}$/
            onCommitted: value => GlobalConfig.search.prefix.webSearch = value
        }

        TextFieldRow {
            label: qsTr("Tiền tố phép tính")
            value: GlobalConfig.search.prefix.math
            placeholder: "="
            leadingIcon: "calculate"
            validate: /^\S{0,8}$/
            onCommitted: value => GlobalConfig.search.prefix.math = value
        }

        TextFieldRow {
            last: true
            label: qsTr("URL công cụ tìm kiếm")
            subtext: qsTr("Chuỗi truy vấn đã mã hóa được nối vào cuối URL")
            value: GlobalConfig.search.engineBaseUrl
            placeholder: "https://www.google.com/search?q="
            leadingIcon: "link"
            validate: /^https?:\/\/.+/
            emptyIsValid: false
            onCommitted: value => GlobalConfig.search.engineBaseUrl = value.trim()
        }

        // Media & lyrics
        SectionHeader {
            text: qsTr("Phương tiện & lời bài hát")
        }

        SelectRow {
            first: true
            label: qsTr("Nguồn lời bài hát")
            subtext: qsTr("Nguồn dùng để lấy lời bài hát đồng bộ")
            menuItems: root.lyricsItems
            active: root.lyricsItems[Lyrics.preferredBackend] ?? root.lyricsItems[0]
            onSelected: item => Lyrics.preferredBackend = root.lyricsItems.indexOf(item)
        }

        SelectRow {
            last: true
            label: qsTr("Trình phát mặc định")
            subtext: qsTr("Trình phát ưu tiên khi mở nhiều trình phát")
            menuItems: playerVariants.instances
            active: menuItems.find(i => i.text === GlobalConfig.services.defaultPlayer) ?? null
            fallbackIcon: "music_note"
            fallbackText: GlobalConfig.services.defaultPlayer || qsTr("Tự động")
            onSelected: item => GlobalConfig.services.defaultPlayer = item.text
        }

        // Input increments
        SectionHeader {
            text: qsTr("Mức điều chỉnh")
        }

        StepperRow {
            first: true
            label: qsTr("Bước âm lượng")
            subtext: qsTr("Mức thay đổi âm lượng mỗi lần cuộn (%)")
            value: Math.round(GlobalConfig.services.audioIncrement * 100)
            from: 1
            to: 50
            stepSize: 1
            onMoved: v => GlobalConfig.services.audioIncrement = v / 100
        }

        StepperRow {
            label: qsTr("Bước độ sáng")
            subtext: qsTr("Mức thay đổi độ sáng mỗi lần cuộn (%)")
            value: Math.round(GlobalConfig.services.brightnessIncrement * 100)
            from: 1
            to: 50
            stepSize: 1
            onMoved: v => GlobalConfig.services.brightnessIncrement = v / 100
        }

        StepperRow {
            last: true
            label: qsTr("Âm lượng tối đa")
            subtext: qsTr("Giới hạn trên của âm lượng đầu ra (%)")
            value: Math.round(GlobalConfig.services.maxVolume * 100)
            from: 50
            to: 200
            stepSize: 5
            onMoved: v => GlobalConfig.services.maxVolume = v / 100
        }

        SectionHeader {
            text: qsTr("Bảo vệ âm lượng")
        }

        ToggleRow {
            first: true
            text: qsTr("Chặn tăng âm lượng đột ngột")
            subtext: qsTr("Theo dõi thay đổi từ ứng dụng bên ngoài; thao tác chủ động trong Caelestia vẫn được phép")
            checked: GlobalConfig.services.audioProtection.enabled
            onToggled: GlobalConfig.services.audioProtection.enabled = checked
        }

        StepperRow {
            enabled: GlobalConfig.services.audioProtection.enabled
            opacity: enabled ? 1 : 0.55
            last: true
            label: qsTr("Mức tăng tối đa mỗi lần")
            subtext: qsTr("Chặn thay đổi đầu ra lớn hơn tỷ lệ này (%)")
            value: Math.round(GlobalConfig.services.audioProtection.maxIncrease * 100)
            from: 0
            to: 100
            stepSize: 1
            onMoved: v => GlobalConfig.services.audioProtection.maxIncrease = v / 100
        }

        // Service tuning
        SectionHeader {
            text: qsTr("Tinh chỉnh dịch vụ")
        }

        StepperRow {
            first: true
            label: qsTr("Thanh trực quan hóa")
            subtext: qsTr("Số thanh trực quan hóa âm thanh")
            value: GlobalConfig.services.visualiserBars
            from: 10
            to: 120
            stepSize: 2
            onMoved: v => GlobalConfig.services.visualiserBars = v
        }

        ToggleRow {
            text: qsTr("Bảng màu thông minh")
            subtext: qsTr("Tự xác định chế độ và biến thể màu từ hình nền")
            checked: GlobalConfig.services.smartScheme
            onToggled: GlobalConfig.services.smartScheme = checked
        }

        SelectRow {
            last: true
            label: qsTr("GPU")
            subtext: Gpu.name ? qsTr("Đang giám sát: %1").arg(Gpu.name) : qsTr("Ghi đè loại GPU")
            menuOnTop: true
            menuItems: root.gpuItems
            active: root.gpuItems[root.gpuKeyToIndex(GlobalConfig.services.gpuType)]
            onSelected: item => GlobalConfig.services.gpuType = root.gpuValues[root.gpuItems.indexOf(item)]
        }
    }
}
