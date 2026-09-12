pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.filedialog
import qs.utils

Item {
    id: root

    required property ScreenState screenState
    readonly property FileDialog facePicker: FileDialog {
        targetScreen: root.screenState.modelData
        title: qsTr("Chọn ảnh đại diện")
        filterLabel: qsTr("Tệp hình ảnh")
        filters: Images.validImageExtensions
        onAccepted: path => {
            const localPath = Paths.toLocalFile(path) || path;
            if (GlobalConfig.profile.avatarPath.trim()) {
                GlobalConfig.profile.avatarPicture = localPath;
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "low", "-h", `STRING:image-path:${localPath}`, "Đã đổi ảnh đại diện", `Đã dùng ${Paths.shortenHome(localPath)} làm ảnh đại diện`]);
                return;
            }

            GlobalConfig.profile.avatarPicture = "";
            if (CUtils.copyFile(Qt.resolvedUrl(path), Qt.resolvedUrl(`${Paths.home}/.face`)))
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "low", "-h", `STRING:image-path:${path}`, "Đã đổi ảnh đại diện", `Đã đổi ảnh đại diện thành ${Paths.shortenHome(path)}`]);
            else
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "critical", "Không thể đổi ảnh đại diện", `Không thể đổi ảnh đại diện thành ${Paths.shortenHome(path)}`]);
        }
    }

    readonly property real nonAnimHeight: (content.item as Content)?.nonAnimHeight ?? 0
    readonly property bool shouldBeActive: screenState.dashboard && Config.dashboard.enabled
    property real offsetScale: shouldBeActive ? 0 : 1

    visible: offsetScale < 1
    anchors.topMargin: (-implicitHeight - 5) * offsetScale
    implicitHeight: content.implicitHeight
    implicitWidth: content.implicitWidth || 854 // Hard coded fallback for first open
    opacity: 1 - offsetScale

    Behavior on offsetScale {
        Anim {}
    }

    Loader {
        id: content

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom

        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            screenState: root.screenState
            facePicker: root.facePicker
        }
    }
}
