pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Khay hệ thống")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        ToggleRow {
            first: true
            text: qsTr("Nền")
            checked: Config.bar.tray.background
            onToggled: GlobalConfig.bar.tray.background = checked
        }

        ToggleRow {
            text: qsTr("Đổi màu biểu tượng")
            checked: Config.bar.tray.recolour
            onToggled: GlobalConfig.bar.tray.recolour = checked
        }

        ToggleRow {
            text: qsTr("Thu gọn")
            checked: Config.bar.tray.compact
            onToggled: GlobalConfig.bar.tray.compact = checked
        }

        ToggleRow {
            text: qsTr("Hiện bảng bật ra khi rê chuột")
            subtext: qsTr("Hiện bảng khay hệ thống khi rê chuột")
            checked: Config.bar.popouts.tray
            onToggled: GlobalConfig.bar.popouts.tray = checked
        }

        ToggleRow {
            text: qsTr("Hiện ID mục")
            subtext: qsTr("Hiện định danh của biểu tượng khi rê chuột")
            checked: Config.bar.tray.showItemId
            onToggled: GlobalConfig.bar.tray.showItemId = checked
        }

        ToggleRow {
            text: qsTr("Đảo danh sách ghim")
            subtext: qsTr("Lưu quy tắc whitelist/blacklist tương thích end4")
            checked: Config.bar.tray.invertPinnedItems
            onToggled: GlobalConfig.bar.tray.invertPinnedItems = checked
        }

        TextFieldRow {
            label: qsTr("Mục ghim")
            subtext: qsTr("ID cách nhau bằng dấu phẩy")
            value: Config.bar.tray.pinnedItems.join(", ")
            placeholder: "Fcitx"
            onCommitted: value => GlobalConfig.bar.tray.pinnedItems = value.split(",").map(item => item.trim()).filter(item => item)
        }

        ToggleRow {
            last: true
            text: qsTr("Lọc mục thụ động")
            checked: Config.bar.tray.filterPassive
            onToggled: GlobalConfig.bar.tray.filterPassive = checked
        }
    }
}
