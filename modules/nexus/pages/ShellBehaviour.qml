import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Hành vi shell")

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
            last: true
            text: qsTr("Hiển thị trên ứng dụng toàn màn hình")
            subtext: qsTr("Cho phép các bề mặt shell xuất hiện trên cửa sổ toàn màn hình")
            checked: Config.general.showOverFullscreen
            onToggled: GlobalConfig.general.showOverFullscreen = checked
        }

        SectionHeader {
            text: qsTr("Pin")
        }

        ToggleRow {
            first: true
            text: qsTr("Tự động ngủ đông")
            subtext: qsTr("Ngủ đông khi pin chạm ngưỡng tới hạn")
            checked: GlobalConfig.general.battery.autoHibernate
            onToggled: GlobalConfig.general.battery.autoHibernate = checked
        }

        StepperRow {
            label: qsTr("Ngưỡng ngủ đông")
            subtext: qsTr("Phần trăm pin còn lại trước khi bắt đầu đếm ngược")
            value: GlobalConfig.general.battery.criticalLevel
            from: 1
            to: 20
            stepSize: 1
            onMoved: value => GlobalConfig.general.battery.criticalLevel = Math.round(value)
        }

        StepperRow {
            enabled: GlobalConfig.general.battery.autoHibernate
            opacity: enabled ? 1 : 0.55
            last: true
            label: qsTr("Độ trễ ngủ đông")
            subtext: qsTr("Số giây chờ để người dùng kịp cắm sạc")
            value: GlobalConfig.general.battery.hibernateDelay
            from: 0
            to: 60
            stepSize: 1
            onMoved: value => GlobalConfig.general.battery.hibernateDelay = Math.round(value)
        }

        SectionHeader {
            text: qsTr("Màn hình khóa")
        }

        ToggleRow {
            first: true
            text: qsTr("Bật màn hình khóa")
            checked: Config.lock.enabled
            onToggled: GlobalConfig.lock.enabled = checked
        }

        ToggleRow {
            enabled: Config.lock.enabled
            opacity: enabled ? 1 : 0.55
            text: qsTr("Đổi màu logo")
            checked: Config.lock.recolourLogo
            onToggled: GlobalConfig.lock.recolourLogo = checked
        }

        ToggleRow {
            enabled: Config.lock.enabled
            opacity: enabled ? 1 : 0.55
            text: qsTr("Ẩn nội dung thông báo")
            checked: Config.lock.hideNotifs
            onToggled: GlobalConfig.lock.hideNotifs = checked
        }

        ToggleRow {
            enabled: Config.lock.enabled
            opacity: enabled ? 1 : 0.55
            text: qsTr("Mở khóa bằng vân tay")
            checked: GlobalConfig.lock.enableFprint
            onToggled: GlobalConfig.lock.enableFprint = checked
        }

        StepperRow {
            enabled: Config.lock.enabled && GlobalConfig.lock.enableFprint
            opacity: enabled ? 1 : 0.55
            label: qsTr("Số lần thử vân tay")
            value: GlobalConfig.lock.maxFprintTries
            from: 1
            to: 10
            stepSize: 1
            onMoved: value => GlobalConfig.lock.maxFprintTries = Math.round(value)
        }

        ToggleRow {
            enabled: Config.lock.enabled
            opacity: enabled ? 1 : 0.55
            text: qsTr("Mở khóa bằng Howdy")
            checked: GlobalConfig.lock.enableHowdy
            onToggled: GlobalConfig.lock.enableHowdy = checked
        }

        StepperRow {
            enabled: Config.lock.enabled && GlobalConfig.lock.enableHowdy
            opacity: enabled ? 1 : 0.55
            label: qsTr("Số lần thử Howdy")
            value: GlobalConfig.lock.maxHowdyTries
            from: 1
            to: 10
            stepSize: 1
            onMoved: value => GlobalConfig.lock.maxHowdyTries = Math.round(value)
        }

        ToggleRow {
            enabled: Config.lock.enabled && GlobalConfig.lock.enableHowdy
            opacity: enabled ? 1 : 0.55
            last: true
            text: qsTr("Chạy Howdy khi đánh thức")
            checked: GlobalConfig.lock.triggerHowdyOnWake
            onToggled: GlobalConfig.lock.triggerHowdyOnWake = checked
        }

        SectionHeader {
            text: qsTr("Hiển thị trên màn hình")
        }

        ToggleRow {
            first: true
            text: qsTr("Bật OSD")
            subtext: qsTr("Hiện mức âm lượng, độ sáng và micrô")
            checked: Config.osd.enabled
            onToggled: GlobalConfig.osd.enabled = checked
        }

        StepperRow {
            enabled: Config.osd.enabled
            opacity: enabled ? 1 : 0.55
            label: qsTr("Thời gian hiển thị")
            subtext: qsTr("Thời gian trước khi OSD tự ẩn (ms)")
            value: Config.osd.hideDelay
            from: 250
            to: 10000
            stepSize: 250
            onMoved: value => GlobalConfig.osd.hideDelay = Math.round(value)
        }

        ToggleRow {
            enabled: Config.osd.enabled
            opacity: enabled ? 1 : 0.55
            text: qsTr("OSD độ sáng")
            checked: Config.osd.enableBrightness
            onToggled: GlobalConfig.osd.enableBrightness = checked
        }

        ToggleRow {
            enabled: Config.osd.enabled
            opacity: enabled ? 1 : 0.55
            last: true
            text: qsTr("OSD micrô")
            checked: Config.osd.enableMicrophone
            onToggled: GlobalConfig.osd.enableMicrophone = checked
        }
    }
}
