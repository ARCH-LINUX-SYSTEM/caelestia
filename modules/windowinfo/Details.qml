import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Caelestia.Config
import qs.components
import qs.services

ColumnLayout {
    id: root

    required property HyprlandToplevel client

    readonly property var ipc: client?.lastIpcObject ?? null
    readonly property var position: ipc?.at ?? []
    readonly property var clientSize: ipc?.size ?? []

    anchors.fill: parent
    spacing: Tokens.spacing.small

    Label {
        Layout.topMargin: Tokens.padding.extraLargeIncreased

        text: root.client?.title ?? qsTr("Không có cửa sổ đang hoạt động")
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere

        font: Tokens.font.body.builders.large.weight(Font.Medium).build()
    }

    Label {
        text: root.ipc?.class ?? qsTr("Không có cửa sổ đang hoạt động")
        color: Colours.palette.m3tertiary

        font: Tokens.font.body.large
    }

    StyledRect {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        Layout.leftMargin: Tokens.padding.extraLargeIncreased
        Layout.rightMargin: Tokens.padding.extraLargeIncreased
        Layout.topMargin: Tokens.spacing.medium
        Layout.bottomMargin: Tokens.spacing.largeIncreased

        color: Colours.palette.m3secondary
    }

    Detail {
        icon: "location_on"
        text: {
            const address = root.client?.address;
            return qsTr("Địa chỉ: %1").arg(address ? `0x${address}` : "không xác định");
        }
        color: Colours.palette.m3primary
    }

    Detail {
        icon: "location_searching"
        text: qsTr("Vị trí: %1, %2").arg(root.position[0] ?? -1).arg(root.position[1] ?? -1)
    }

    Detail {
        icon: "resize"
        text: qsTr("Kích thước: %1 x %2").arg(root.clientSize[0] ?? -1).arg(root.clientSize[1] ?? -1)
        color: Colours.palette.m3tertiary
    }

    Detail {
        icon: "workspaces"
        text: qsTr("Không gian làm việc: %1 (%2)").arg(root.client?.workspace?.name ?? -1).arg(root.client?.workspace?.id ?? -1)
        color: Colours.palette.m3secondary
    }

    Detail {
        icon: "desktop_windows"
        text: {
            const mon = root.client?.monitor;
            if (mon)
                return qsTr("Màn hình: %1 (%2) tại %3, %4").arg(mon.name).arg(mon.id).arg(mon.x).arg(mon.y);
            return qsTr("Màn hình: không xác định");
        }
    }

    Detail {
        icon: "page_header"
        text: qsTr("Tiêu đề ban đầu: %1").arg(root.ipc?.initialTitle ?? "không xác định")
        color: Colours.palette.m3tertiary
    }

    Detail {
        icon: "category"
        text: qsTr("Class ban đầu: %1").arg(root.ipc?.initialClass ?? "không xác định")
    }

    Detail {
        icon: "account_tree"
        text: qsTr("ID tiến trình: %1").arg(String(root.ipc?.pid ?? -1))
        color: Colours.palette.m3primary
    }

    Detail {
        icon: "picture_in_picture_center"
        text: qsTr("Thả nổi: %1").arg(root.ipc?.floating ? "có" : "không")
        color: Colours.palette.m3secondary
    }

    Detail {
        icon: "gradient"
        text: qsTr("Xwayland: %1").arg(root.ipc?.xwayland ? "có" : "không")
    }

    Detail {
        icon: "keep"
        text: qsTr("Đã ghim: %1").arg(root.ipc?.pinned ? "có" : "không")
        color: Colours.palette.m3secondary
    }

    Detail {
        icon: "fullscreen"
        text: {
            const fs = root.ipc?.fullscreen;
            if (fs === undefined || fs === null)
                return qsTr("Trạng thái toàn màn hình: không xác định");
            return qsTr("Trạng thái toàn màn hình: %1").arg(fs === 0 ? "tắt" : fs === 1 ? "phóng to" : "bật");
        }
        color: Colours.palette.m3tertiary
    }

    Item {
        Layout.fillHeight: true
    }

    component Detail: RowLayout {
        id: detail

        required property string icon
        required property string text
        property alias color: icon.color

        Layout.leftMargin: Tokens.padding.large
        Layout.rightMargin: Tokens.padding.large
        Layout.fillWidth: true

        spacing: Tokens.spacing.medium

        MaterialIcon {
            id: icon

            Layout.alignment: Qt.AlignVCenter
            text: detail.icon
        }

        StyledText {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            text: detail.text
            elide: Text.ElideRight
            font: Tokens.font.body.medium
        }
    }

    component Label: StyledText {
        Layout.leftMargin: Tokens.padding.large
        Layout.rightMargin: Tokens.padding.large
        Layout.fillWidth: true
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        animate: true
    }
}
