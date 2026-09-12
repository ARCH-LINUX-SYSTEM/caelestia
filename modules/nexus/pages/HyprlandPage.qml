pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property bool managed: GlobalConfig.hyprland.enabled
    readonly property list<MenuItem> animationPresetItems: [
        MenuItem {
            text: qsTr("Nhanh")
        },
        MenuItem {
            text: qsTr("Bình thường")
        },
        MenuItem {
            text: "Niri"
        }
    ]
    readonly property list<string> animationPresetValues: ["fast", "normal", "niri"]

    function monitorDetails(monitor: var): string {
        return qsTr("%1 × %2 • tỷ lệ %3").arg(monitor.width).arg(monitor.height).arg(Number(monitor.scale).toFixed(2));
    }

    function availabilityText(description: string, supported: bool): string {
        return supported ? description : qsTr("%1 • không được phiên bản Hyprland này hỗ trợ").arg(description);
    }

    function animationPresetIndex(value: string): int {
        return Math.max(0, animationPresetValues.indexOf(value));
    }

    title: "Hyprland"

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Điều khiển thời gian chạy")
        }

        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: runtimeLayout.implicitHeight + runtimeLayout.anchors.margins * 2

            RowLayout {
                id: runtimeLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    Layout.alignment: Qt.AlignTop
                    text: "info"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.medium
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.extraSmall

                    StyledText {
                        Layout.fillWidth: true
                        text: root.managed ? qsTr("Các thay đổi được lưu trong cấu hình Caelestia và áp dụng lại bằng IPC khi shell khởi động.") : qsTr("Các thay đổi ở trang này chỉ áp dụng trong phiên Hyprland hiện tại.")
                        font: Tokens.font.body.small
                        wrapMode: Text.WordWrap
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Caelestia không ghi đè hyprland.conf; nút Nạp lại cấu hình vẫn đọc thiết lập từ đĩa.")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.small
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }

        SectionHeader {
            text: qsTr("Lưu cấu hình")
        }

        ToggleRow {
            first: true
            last: true
            text: qsTr("Caelestia quản lý các tùy chọn Hyprland")
            subtext: qsTr("Mặc định tắt để giữ nguyên cấu hình Hyprland hiện tại")
            checked: root.managed
            onToggled: GlobalConfig.hyprland.enabled = checked
        }

        SectionHeader {
            text: qsTr("Trạng thái")
        }

        InfoRow {
            first: true
            icon: "account_tree"
            label: qsTr("Nhà cung cấp cấu hình")
            subtext: HyprControl.providerReady ? qsTr("Đã sẵn sàng nhận thay đổi có kiểu dữ liệu cố định") : qsTr("Đang chờ Hyprland và danh sách tùy chọn")
            value: HyprControl.providerName
        }

        InfoRow {
            icon: "monitor"
            label: qsTr("Màn hình đang tập trung")
            value: HyprControl.focusedMonitorName || "—"
        }

        InfoRow {
            icon: "workspaces"
            label: qsTr("Không gian làm việc đang hoạt động")
            value: HyprControl.activeWorkspaceName || "—"
        }

        InfoRow {
            icon: "dashboard"
            label: qsTr("Không gian làm việc")
            value: HyprControl.workspaceCount.toString()
        }

        InfoRow {
            last: true
            icon: "window"
            label: qsTr("Cửa sổ")
            value: HyprControl.windowCount.toString()
        }

        SectionHeader {
            text: qsTr("Thao tác")
        }

        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: actionRow.implicitHeight + Tokens.padding.medium * 2

            RowLayout {
                id: actionRow

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                spacing: Tokens.spacing.small

                IconTextButton {
                    Layout.fillWidth: true
                    icon: "refresh"
                    text: qsTr("Làm mới trạng thái")
                    type: IconTextButton.Tonal
                    onClicked: HyprControl.refresh()
                }

                IconTextButton {
                    Layout.fillWidth: true
                    icon: "restart_alt"
                    text: qsTr("Nạp lại cấu hình")
                    type: IconTextButton.Tonal
                    disabled: !HyprControl.providerReady
                    onClicked: HyprControl.reload()
                }
            }
        }

        SectionHeader {
            text: qsTr("Màn hình")
        }

        InfoRow {
            visible: HyprControl.monitorCount === 0
            first: true
            last: true
            icon: "monitor_off"
            label: qsTr("Chưa phát hiện màn hình")
            subtext: qsTr("Bấm Làm mới trạng thái sau khi Hyprland khởi động xong")
        }

        Repeater {
            id: monitorRepeater

            model: HyprControl.monitors

            InfoRow {
                required property var modelData
                required property int index

                first: index === 0
                last: index === monitorRepeater.count - 1
                icon: modelData.focused ? "monitor" : "desktop_windows"
                iconColour: modelData.focused ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                label: modelData.name
                subtext: root.monitorDetails(modelData)
                value: modelData.activeWorkspace?.name ?? "—"
            }
        }

        SectionHeader {
            text: qsTr("Hiệu năng")
        }

        ToggleRow {
            enabled: HyprControl.providerReady
            opacity: enabled ? 1 : 0.55
            first: true
            last: true
            text: qsTr("Chế độ trò chơi")
            subtext: qsTr("Tạm tắt hiệu ứng và khoảng cách; khôi phục đúng giá trị trước đó khi tắt")
            checked: GameMode.enabled
            onToggled: GameMode.enabled = checked
        }

        SectionHeader {
            text: qsTr("Hiệu ứng")
        }

        ToggleRow {
            enabled: HyprControl.providerReady && HyprControl.supportsAnimations && !GameMode.enabled
            opacity: enabled ? 1 : 0.55
            first: true
            text: qsTr("Hiệu ứng động")
            subtext: root.availabilityText(qsTr("Bật chuyển động của cửa sổ và không gian làm việc"), HyprControl.supportsAnimations)
            checked: root.managed ? GlobalConfig.hyprland.animations.enabled : HyprControl.animationsEnabled
            onToggled: {
                if (root.managed)
                    GlobalConfig.hyprland.animations.enabled = checked;
                else
                    HyprControl.setAnimationsEnabled(checked);
            }
        }

        SelectRow {
            enabled: root.managed && HyprControl.providerReady && !GameMode.enabled
            opacity: enabled ? 1 : 0.55
            label: qsTr("Preset chuyển động")
            subtext: qsTr("Đường cong và tốc độ Fast, Normal hoặc kiểu Niri")
            menuItems: root.animationPresetItems
            active: root.animationPresetItems[root.animationPresetIndex(GlobalConfig.hyprland.animations.animation)]
            onSelected: item => GlobalConfig.hyprland.animations.animation = root.animationPresetValues[root.animationPresetItems.indexOf(item)]
        }

        ToggleRow {
            enabled: HyprControl.providerReady && HyprControl.supportsBlur && !GameMode.enabled
            opacity: enabled ? 1 : 0.55
            text: qsTr("Làm mờ")
            subtext: root.availabilityText(qsTr("Bật hiệu ứng làm mờ nền cửa sổ"), HyprControl.supportsBlur)
            checked: root.managed ? GlobalConfig.hyprland.decoration.blur.enabled : HyprControl.blurEnabled
            onToggled: {
                if (root.managed)
                    GlobalConfig.hyprland.decoration.blur.enabled = checked;
                else
                    HyprControl.setBlurEnabled(checked);
            }
        }

        ToggleRow {
            enabled: HyprControl.providerReady && HyprControl.supportsShadow && !GameMode.enabled
            opacity: enabled ? 1 : 0.55
            last: true
            text: qsTr("Bóng đổ")
            subtext: root.availabilityText(qsTr("Bật bóng đổ quanh cửa sổ"), HyprControl.supportsShadow)
            checked: root.managed ? GlobalConfig.hyprland.decoration.shadow.enabled : HyprControl.shadowEnabled
            onToggled: {
                if (root.managed)
                    GlobalConfig.hyprland.decoration.shadow.enabled = checked;
                else
                    HyprControl.setShadowEnabled(checked);
            }
        }

        SectionHeader {
            text: qsTr("Ứng dụng khởi động")
        }

        ToggleRow {
            first: true
            text: qsTr("Chạy danh sách autostart")
            subtext: qsTr("Hỗ trợ command/cmd, workspace và delay; chỉ tự chạy một lần trong mỗi phiên đăng nhập")
            checked: GlobalConfig.hyprland.autostartApps.enabled
            onToggled: GlobalConfig.hyprland.autostartApps.enabled = checked
        }

        InfoRow {
            icon: "playlist_play"
            label: qsTr("Số mục đã cấu hình")
            subtext: qsTr("Có thể dùng chuỗi lệnh hoặc object tương thích config end4")
            value: GlobalConfig.hyprland.autostartApps.apps.length.toString()
        }

        ConnectedRect {
            Layout.fillWidth: true
            last: true
            implicitHeight: runAutostart.implicitHeight + Tokens.padding.medium * 2

            IconTextButton {
                id: runAutostart

                anchors.centerIn: parent
                icon: "motion_play"
                text: qsTr("Chạy danh sách ngay")
                type: IconTextButton.Tonal
                disabled: !GlobalConfig.hyprland.autostartApps.enabled || GlobalConfig.hyprland.autostartApps.apps.length === 0
                onClicked: HyprlandSettings.runAutostart()
            }
        }

        SectionHeader {
            text: qsTr("Bố cục cửa sổ")
        }

        StepperRow {
            enabled: HyprControl.providerReady && HyprControl.supportsGapsIn && !GameMode.enabled
            opacity: enabled ? 1 : 0.55
            first: true
            label: qsTr("Khoảng cách bên trong")
            subtext: root.availabilityText(qsTr("Hiển thị cạnh đầu; thay đổi sẽ đặt đều mọi cạnh (0–100 px)"), HyprControl.supportsGapsIn)
            value: root.managed ? GlobalConfig.hyprland.general.gapsIn : HyprControl.gapsIn
            from: 0
            to: root.managed ? 40 : 100
            stepSize: 1
            onMoved: value => {
                if (root.managed)
                    GlobalConfig.hyprland.general.gapsIn = Math.round(value);
                else
                    HyprControl.setGapsIn(value);
            }
        }

        StepperRow {
            enabled: HyprControl.providerReady && HyprControl.supportsGapsOut && !GameMode.enabled
            opacity: enabled ? 1 : 0.55
            label: qsTr("Khoảng cách bên ngoài")
            subtext: root.availabilityText(qsTr("Hiển thị cạnh đầu; thay đổi sẽ đặt đều mọi cạnh (0–100 px)"), HyprControl.supportsGapsOut)
            value: root.managed ? GlobalConfig.hyprland.general.gapsOut : HyprControl.gapsOut
            from: 0
            to: root.managed ? 60 : 100
            stepSize: 1
            onMoved: value => {
                if (root.managed)
                    GlobalConfig.hyprland.general.gapsOut = Math.round(value);
                else
                    HyprControl.setGapsOut(value);
            }
        }

        StepperRow {
            enabled: HyprControl.providerReady && HyprControl.supportsBorderSize && !GameMode.enabled
            opacity: enabled ? 1 : 0.55
            label: qsTr("Độ dày viền")
            subtext: root.availabilityText(qsTr("Độ dày viền cửa sổ (0–20 px)"), HyprControl.supportsBorderSize)
            value: root.managed ? GlobalConfig.hyprland.general.borderSize : HyprControl.borderSize
            from: 0
            to: root.managed ? 10 : 20
            stepSize: 1
            onMoved: value => {
                if (root.managed)
                    GlobalConfig.hyprland.general.borderSize = Math.round(value);
                else
                    HyprControl.setBorderSize(value);
            }
        }

        StepperRow {
            enabled: HyprControl.providerReady && HyprControl.supportsRounding && !GameMode.enabled
            opacity: enabled ? 1 : 0.55
            last: true
            label: qsTr("Bo góc")
            subtext: root.availabilityText(qsTr("Bán kính bo góc cửa sổ (0–100 px)"), HyprControl.supportsRounding)
            value: root.managed ? GlobalConfig.hyprland.decoration.rounding : HyprControl.rounding
            from: 0
            to: root.managed ? 30 : 100
            stepSize: 1
            onMoved: value => {
                if (root.managed)
                    GlobalConfig.hyprland.decoration.rounding = Math.round(value);
                else
                    HyprControl.setRounding(value);
            }
        }
    }
}
