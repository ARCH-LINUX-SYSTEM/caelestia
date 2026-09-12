pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property list<MenuItem> capitalisationItems: [
        MenuItem {
            text: qsTr("Giữ nguyên")
        },
        MenuItem {
            text: qsTr("Chữ hoa")
        },
        MenuItem {
            text: qsTr("Chữ thường")
        }
    ]
    readonly property list<string> capitalisationValues: ["preserve", "upper", "lower"]
    readonly property list<MenuItem> indicatorStyleItems: [
        MenuItem {
            text: qsTr("Chấm")
        },
        MenuItem {
            text: qsTr("Biểu tượng")
        }
    ]
    readonly property list<string> indicatorStyleValues: ["dot", "icon"]

    function capitalisationIndex(value: string): int {
        return Math.max(0, capitalisationValues.indexOf(value.toLowerCase()));
    }

    title: qsTr("Không gian làm việc")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        StepperRow {
            first: true
            label: qsTr("Số lượng hiển thị")
            subtext: qsTr("Số không gian làm việc được hiển thị")
            value: Config.bar.workspaces.shown
            from: 1
            to: 20
            stepSize: 1
            onMoved: v => GlobalConfig.bar.workspaces.shown = v
        }

        ToggleRow {
            text: qsTr("Chỉ báo hoạt động")
            checked: Config.bar.workspaces.activeIndicator
            onToggled: GlobalConfig.bar.workspaces.activeIndicator = checked
        }

        ToggleRow {
            text: qsTr("Vệt hoạt động")
            checked: Config.bar.workspaces.activeTrail
            onToggled: GlobalConfig.bar.workspaces.activeTrail = checked
        }

        ToggleRow {
            text: qsTr("Nền vùng làm việc có cửa sổ")
            checked: Config.bar.workspaces.occupiedBg
            onToggled: GlobalConfig.bar.workspaces.occupiedBg = checked
        }

        ToggleRow {
            text: qsTr("Hiện cửa sổ")
            subtext: qsTr("Hiện biểu tượng cửa sổ đang mở trên từng không gian làm việc")
            checked: Config.bar.workspaces.showWindows
            onToggled: GlobalConfig.bar.workspaces.showWindows = checked
        }

        ToggleRow {
            text: qsTr("Cửa sổ trên không gian làm việc đặc biệt")
            checked: Config.bar.workspaces.showWindowsOnSpecialWorkspaces
            onToggled: GlobalConfig.bar.workspaces.showWindowsOnSpecialWorkspaces = checked
        }

        StepperRow {
            label: qsTr("Số biểu tượng cửa sổ tối đa")
            value: Config.bar.workspaces.maxWindowIcons
            from: 0
            to: 20
            stepSize: 1
            onMoved: v => GlobalConfig.bar.workspaces.maxWindowIcons = v
        }

        ToggleRow {
            last: true
            text: qsTr("Không gian làm việc riêng theo màn hình")
            subtext: qsTr("Hiện riêng không gian làm việc của từng màn hình")
            checked: GlobalConfig.bar.workspaces.perMonitorWorkspaces
            onToggled: GlobalConfig.bar.workspaces.perMonitorWorkspaces = checked
        }

        SectionHeader {
            text: qsTr("Hiển thị tương thích")
        }

        ToggleRow {
            first: true
            text: qsTr("Biểu tượng ứng dụng đơn sắc")
            checked: Config.bar.workspaces.monochromeIcons
            onToggled: GlobalConfig.bar.workspaces.monochromeIcons = checked
        }

        ToggleRow {
            text: qsTr("Hiện biểu tượng ứng dụng")
            checked: Config.bar.workspaces.showAppIcons
            onToggled: GlobalConfig.bar.workspaces.showAppIcons = checked
        }

        SelectRow {
            label: qsTr("Kiểu chỉ báo")
            menuItems: root.indicatorStyleItems
            active: root.indicatorStyleItems[Math.max(0, root.indicatorStyleValues.indexOf(Config.bar.workspaces.indicatorStyle))]
            onSelected: item => GlobalConfig.bar.workspaces.indicatorStyle = root.indicatorStyleValues[root.indicatorStyleItems.indexOf(item)]
        }

        ToggleRow {
            text: qsTr("Luôn hiện số")
            checked: Config.bar.workspaces.alwaysShowNumbers
            onToggled: GlobalConfig.bar.workspaces.alwaysShowNumbers = checked
        }

        StepperRow {
            enabled: Config.bar.workspaces.alwaysShowNumbers
            opacity: enabled ? 1 : 0.55
            label: qsTr("Độ trễ hiện số")
            subtext: qsTr("Mili giây")
            value: Config.bar.workspaces.showNumberDelay
            from: 0
            to: 10000
            stepSize: 50
            onMoved: value => GlobalConfig.bar.workspaces.showNumberDelay = Math.round(value)
        }

        TextFieldRow {
            enabled: Config.bar.workspaces.alwaysShowNumbers
            opacity: enabled ? 1 : 0.55
            label: qsTr("Ánh xạ số")
            subtext: qsTr("Danh sách cách nhau bằng dấu phẩy; để trống để dùng số thường")
            value: Config.bar.workspaces.numberMap.join(", ")
            placeholder: "1, 2, 3"
            onCommitted: value => GlobalConfig.bar.workspaces.numberMap = value.split(",").map(item => item.trim()).filter(item => item)
        }

        ToggleRow {
            last: true
            enabled: Config.bar.workspaces.alwaysShowNumbers
            opacity: enabled ? 1 : 0.55
            text: qsTr("Dùng Nerd Font cho số")
            checked: Config.bar.workspaces.useNerdFont
            onToggled: GlobalConfig.bar.workspaces.useNerdFont = checked
        }

        SectionHeader {
            text: qsTr("Nhãn chỉ báo")
        }

        TextFieldRow {
            first: true
            label: qsTr("Không có cửa sổ")
            subtext: qsTr("Để trống để dùng tên hoặc số không gian làm việc")
            value: Config.bar.workspaces.label
            placeholder: qsTr("Tên không gian làm việc")
            onCommitted: value => GlobalConfig.bar.workspaces.label = value
        }

        TextFieldRow {
            label: qsTr("Có cửa sổ")
            subtext: qsTr("Nhãn dùng khi không gian làm việc có cửa sổ")
            value: Config.bar.workspaces.occupiedLabel
            placeholder: qsTr("Nhãn đang dùng")
            onCommitted: value => GlobalConfig.bar.workspaces.occupiedLabel = value
        }

        TextFieldRow {
            label: qsTr("Đang hoạt động")
            subtext: qsTr("Nhãn dùng cho không gian làm việc hiện tại")
            value: Config.bar.workspaces.activeLabel
            placeholder: qsTr("Nhãn hoạt động")
            onCommitted: value => GlobalConfig.bar.workspaces.activeLabel = value
        }

        SelectRow {
            last: true
            label: qsTr("Kiểu chữ")
            subtext: qsTr("Áp dụng khi nhãn lấy từ tên không gian làm việc")
            menuItems: root.capitalisationItems
            active: root.capitalisationItems[root.capitalisationIndex(Config.bar.workspaces.capitalisation)]
            onSelected: item => GlobalConfig.bar.workspaces.capitalisation = root.capitalisationValues[root.capitalisationItems.indexOf(item)]
        }
    }
}
