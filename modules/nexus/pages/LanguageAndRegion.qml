import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    // Temperature units (index 0 = Celsius, 1 = Fahrenheit — matches Weather.formatTemp)
    readonly property list<MenuItem> tempItems: [
        MenuItem {
            text: "°C"
        },
        MenuItem {
            text: "°F"
        }
    ]

    // Clock format (index 0 = 24-hour, 1 = 12-hour — matches Time.useTwelveHourClock)
    readonly property list<MenuItem> clockItems: [
        MenuItem {
            text: qsTr("24 giờ")
        },
        MenuItem {
            text: qsTr("12 giờ")
        }
    ]

    title: qsTr("Ngôn ngữ & khu vực")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Language
        SectionHeader {
            first: true
            text: qsTr("Ngôn ngữ")
        }

        TextFieldRow {
            first: true
            last: true
            label: qsTr("Ngôn ngữ giao diện")
            subtext: qsTr("Dùng “auto” để theo hệ thống; ví dụ vi_VN hoặc en_US")
            value: GlobalConfig.language.ui
            placeholder: "auto"
            leadingIcon: "translate"
            onCommitted: value => GlobalConfig.language.ui = value.trim() || "auto"
        }

        // Weather
        SectionHeader {
            text: qsTr("Thời tiết")
        }

        ToggleRow {
            first: true
            text: qsTr("Tự xác định vị trí")
            subtext: qsTr("Dùng vị trí IP khi thanh thời tiết không có cấu hình riêng")
            checked: GlobalConfig.services.weatherUseGps
            onToggled: GlobalConfig.services.weatherUseGps = checked
        }

        TextFieldRow {
            enabled: !GlobalConfig.services.weatherUseGps
            opacity: enabled ? 1 : 0.55
            label: qsTr("Vị trí thời tiết")
            subtext: qsTr("Tên thành phố hoặc tọa độ “vĩ độ,kinh độ”")
            value: GlobalConfig.services.weatherLocation
            placeholder: "Hồ Chí Minh"
            leadingIcon: "location_on"
            onCommitted: value => GlobalConfig.services.weatherLocation = value.trim()
        }

        StepperRow {
            last: true
            label: qsTr("Chu kỳ cập nhật")
            subtext: qsTr("Phút giữa các lần tải dữ liệu thời tiết")
            value: GlobalConfig.services.weatherFetchInterval
            from: 5
            to: 1440
            stepSize: 5
            onMoved: value => GlobalConfig.services.weatherFetchInterval = Math.round(value)
        }

        // Units
        SectionHeader {
            text: qsTr("Đơn vị")
        }

        SelectRow {
            first: true
            label: qsTr("Nhiệt độ")
            subtext: qsTr("Đơn vị nhiệt độ thời tiết")
            menuItems: root.tempItems
            active: root.tempItems[GlobalConfig.services.useFahrenheit ? 1 : 0]
            onSelected: item => GlobalConfig.services.useFahrenheit = root.tempItems.indexOf(item) === 1
        }

        SelectRow {
            last: true
            label: qsTr("Nhiệt độ hệ thống")
            subtext: qsTr("Đơn vị nhiệt độ CPU và GPU")
            menuItems: root.tempItems
            active: root.tempItems[GlobalConfig.services.useFahrenheitPerformance ? 1 : 0]
            onSelected: item => GlobalConfig.services.useFahrenheitPerformance = root.tempItems.indexOf(item) === 1
        }

        // Time & date
        SectionHeader {
            text: qsTr("Ngày & giờ")
        }

        SelectRow {
            first: true
            label: qsTr("Định dạng đồng hồ")
            subtext: qsTr("Cách hiển thị thời gian trong toàn bộ giao diện")
            menuItems: root.clockItems
            active: root.clockItems[GlobalConfig.services.useTwelveHourClock ? 1 : 0]
            onSelected: item => GlobalConfig.services.useTwelveHourClock = root.clockItems.indexOf(item) === 1
        }

        TextFieldRow {
            last: true
            label: qsTr("Locale lịch")
            subtext: qsTr("Quy tắc tên tháng, thứ và ngày đầu tuần")
            value: GlobalConfig.services.calendarLocale
            placeholder: "vi_VN"
            leadingIcon: "calendar_month"
            onCommitted: value => GlobalConfig.services.calendarLocale = value.trim() || Qt.locale().name
        }
    }
}
