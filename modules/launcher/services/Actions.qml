pragma Singleton

import ".."
import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.Services
import qs.services
import qs.utils

Searcher {
    id: root

    readonly property list<var> systemActions: [
        {
            name: qsTr("Cài đặt Bluetooth"),
            description: qsTr("Mở trình quản lý Bluetooth đã cấu hình"),
            icon: "bluetooth",
            command: GlobalConfig.general.apps.bluetooth
        },
        {
            name: qsTr("Đổi mật khẩu"),
            description: qsTr("Chạy lệnh đổi mật khẩu đã cấu hình"),
            icon: "password",
            command: GlobalConfig.general.apps.changePassword
        },
        {
            name: qsTr("Cài đặt mạng"),
            description: qsTr("Mở trình quản lý mạng đã cấu hình"),
            icon: "wifi",
            command: GlobalConfig.general.apps.network
        },
        {
            name: qsTr("Quản lý người dùng"),
            description: qsTr("Mở công cụ quản lý người dùng đã cấu hình"),
            icon: "manage_accounts",
            command: GlobalConfig.general.apps.manageUser
        },
        {
            name: qsTr("Cài đặt Ethernet"),
            description: qsTr("Mở trình quản lý Ethernet đã cấu hình"),
            icon: "settings_ethernet",
            command: GlobalConfig.general.apps.networkEthernet
        },
        {
            name: qsTr("Trình quản lý tác vụ"),
            description: qsTr("Mở trình quản lý tiến trình đã cấu hình"),
            icon: "monitoring",
            command: GlobalConfig.general.apps.taskManager
        },
        {
            name: qsTr("Cập nhật hệ thống"),
            description: qsTr("Chạy lệnh cập nhật hệ thống đã cấu hình"),
            icon: "system_update",
            command: GlobalConfig.general.apps.update
        }
    ]

    function transformSearch(search: string): string {
        return search.slice(GlobalConfig.launcher.actionPrefix.length);
    }

    list: variants.instances
    useFuzzy: GlobalConfig.launcher.useFuzzy.actions
    useSloppy: GlobalConfig.search.sloppy

    Variants {
        id: variants

        model: [...GlobalConfig.launcher.actions, ...root.systemActions].filter(a => (a.enabled ?? true) && (GlobalConfig.launcher.enableDangerousActions || !(a.dangerous ?? false)))

        Action {}
    }

    component Action: QtObject {
        required property var modelData
        readonly property string name: modelData.name ?? qsTr("Chưa đặt tên")
        readonly property string desc: modelData.description ?? qsTr("Không có mô tả")
        readonly property string icon: modelData.icon ?? "help_outline"
        readonly property list<string> command: modelData.command ?? []
        readonly property bool enabled: modelData.enabled ?? true
        readonly property bool dangerous: modelData.dangerous ?? false

        function onClicked(list: AppList): void {
            if (command.length === 0)
                return;

            if (command[0] === "autocomplete" && command.length > 1) {
                list.search.text = `${GlobalConfig.launcher.actionPrefix}${command[1]} `;
            } else if (command[0] === "setMode" && command.length > 1) {
                list.screenState.launcher = false;
                Colours.setMode(command[1]);
            } else {
                list.screenState.launcher = false;
                if (!SessionManager.exec(command))
                    Quickshell.execDetached(command);
            }
        }
    }
}
