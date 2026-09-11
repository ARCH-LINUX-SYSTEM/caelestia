pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils

Item {
    id: root

    property string animState: showWallpapers ? "wallpapers" : "apps"
    required property var content
    readonly property var currentList: showWallpapers ? wallpaperList.realList : appList.item
    required property real maxHeight
    required property int padding
    required property var panels
    required property int rounding
    required property ScreenState screenState
    required property SearchBar search
    readonly property bool showWallpapers: search.text.startsWith(`${GlobalConfig.launcher.actionPrefix}wallpaper `)

    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    clip: true
    state: animState
    states: [
        State {
            name: "apps"

            PropertyChanges {
                appList.active: true
                root.implicitHeight: Math.min(root.maxHeight, appList.implicitHeight > 0 ? appList.implicitHeight : empty.implicitHeight)
                root.implicitWidth: root.Tokens.sizes.launcher.itemWidth
            }
            AnchorChanges {
                anchors.left: root.parent.left
                anchors.right: root.parent.right
            }
        },
        State {
            name: "wallpapers"

            PropertyChanges {
                root.implicitHeight: root.Tokens.sizes.launcher.wallpaperHeight + 56
                root.implicitWidth: Math.max(root.Tokens.sizes.launcher.itemWidth * 1.2, wallpaperList.implicitWidth)
                wallpaperList.active: true
            }
        }
    ]

    Behavior on animState {
        SequentialAnimation {
            Anim {
                from: 1
                property: "opacity"
                target: root
                to: 0
                type: Anim.DefaultEffects
            }
            Anim {
                from: 0
                property: "opacity"
                target: root
                to: 1
                type: Anim.DefaultEffects
            }
        }
    }
    Behavior on implicitHeight {
        enabled: root.screenState.launcher

        Anim {}
    }
    Behavior on implicitWidth {
        enabled: root.screenState.launcher

        Anim {}
    }
    Loader {
        id: appList

        active: false
        anchors.fill: parent

        sourceComponent: AppList {
            objectName: "launcherAppList"
            screenState: root.screenState
            search: root.search
        }
    }
    Loader {
        id: wallpaperList

        property var realList: null

        active: false
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        asynchronous: true

        sourceComponent: ColumnLayout {
            readonly property int count: listComp.count

            implicitWidth: listComp.implicitWidth
            spacing: Tokens.spacing.medium

            Component.onCompleted: wallpaperList.realList = listComp
            Component.onDestruction: {
                if (wallpaperList.realList === listComp)
                    wallpaperList.realList = null;
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Tokens.spacing.medium * 1.06

                IconTextButton {
                    font: Tokens.font.body.small
                    horizontalPadding: Tokens.padding.medium
                    icon: "image"
                    isRound: true
                    text: qsTr("Tĩnh")
                    type: Wallpapers.wallpaperMode === "static" ? IconTextButton.Filled : IconTextButton.Tonal
                    verticalPadding: Tokens.padding.extraSmall

                    onClicked: Wallpapers.setWallpaperMode("static")
                }
                IconTextButton {
                    font: Tokens.font.body.small
                    horizontalPadding: Tokens.padding.medium
                    icon: "movie"
                    isRound: true
                    text: qsTr("Động")
                    type: Wallpapers.wallpaperMode === "animated" ? IconTextButton.Filled : IconTextButton.Tonal
                    verticalPadding: Tokens.padding.extraSmall

                    onClicked: Wallpapers.setWallpaperMode("animated")
                }
                IconTextButton {
                    font: Tokens.font.body.small
                    horizontalPadding: Tokens.padding.medium
                    icon: "refresh"
                    isRound: true
                    scale: 0.9
                    text: qsTr("Làm mới")
                    type: IconTextButton.Tonal
                    verticalPadding: Tokens.padding.extraSmall
                    visible: Wallpapers.wallpaperMode === "animated"

                    onClicked: {
                        Wallpapers.refreshAnimatedThumbs();
                    }
                }
                Timer {
                    id: processingDotsTimer

                    interval: 400
                    repeat: true
                    running: Wallpapers._refreshing && Wallpapers.wallpaperMode === "animated"

                    onTriggered: processingText.dotCount = (processingText.dotCount % 3) + 1
                }
                Text {
                    id: processingText

                    property int dotCount: 1

                    Layout.alignment: Qt.AlignVCenter
                    color: Colours.palette.m3secondary
                    font: Tokens.font.body.small
                    text: qsTr("Đang xử lý") + ".".repeat(dotCount)
                    visible: processingDotsTimer.running
                }
            }
            WallpaperList {
                id: listComp

                Layout.fillHeight: true
                Layout.fillWidth: true
                content: root.content
                objectName: "launcherWallpaperList"
                panels: root.panels
                screenState: root.screenState
                search: root.search
            }
        }
    }
    Row {
        id: empty

        readonly property int count: root.currentList?.count ?? 0

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        opacity: count === 0 ? 1 : 0
        padding: Tokens.padding.large
        scale: count === 0 ? 1 : 0.5
        spacing: Tokens.spacing.medium

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
        Behavior on scale {
            Anim {}
        }

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.extraLarge
            text: root.state === "wallpapers" ? "wallpaper_slideshow" : "manage_search"
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter

            StyledText {
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.builders.large.weight(Font.Medium).build()
                text: root.state === "wallpapers" ? qsTr("Không tìm thấy hình nền") : qsTr("Không có kết quả")
            }
            StyledText {
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.medium
                text: root.state === "wallpapers" && Wallpapers.list.length === 0 ? qsTr("Hãy thêm một số hình nền vào %1").arg(Paths.shortenHome(Paths.wallsdir)) : qsTr("Hãy thử tìm nội dung khác")
            }
        }
    }
}
