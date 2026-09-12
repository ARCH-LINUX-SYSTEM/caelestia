pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Dialogs as SystemDialogs
import QtQuick.Layouts
import Quickshell
import Caelestia.Components
import Caelestia.Config
import Caelestia.Models
import qs.components
import qs.components.controls
import qs.components.filedialog
import qs.components.images
import qs.services
import qs.utils
import qs.modules.nexus.common

// Standalone "switch background" popup: just the wallpaper grid + browse/random
// actions, with no Nexus chrome (nav sidebar, other settings) around it.
Item {
    id: root

    required property ShellScreen targetScreen

    signal requestClose

    readonly property real cappedWidth: (targetScreen?.width ?? 1280) * 0.8

    implicitWidth: cappedWidth
    implicitHeight: layout.implicitHeight + Tokens.padding.extraLargeIncreased * 2

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.extraLargeIncreased
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.fillWidth: true

            Item {
                Layout.fillWidth: true
            }

            IconButton {
                icon: "close"
                type: IconButton.Text
                isRound: true
                font: Tokens.font.icon.medium
                onClicked: root.requestClose()
            }
        }

        ButtonRow {
            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.spacing.small

            IconTextButton {
                icon: "photo_library"
                text: qsTr("Duyệt")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                onClicked: {
                    if (GlobalConfig.nexus.useSystemFileDialog)
                        systemBrowseDialog.open();
                    else
                        browseDialog.open();
                }

                FileDialog {
                    id: browseDialog

                    cwd: ["Home"]
                    targetScreen: root.targetScreen
                    title: qsTr("Chọn hình nền")
                    filterLabel: qsTr("Tệp hình nền")
                    filters: Images.validImageExtensions.concat(Wallpapers.validVideoExtensions)
                    onAccepted: path => root.selectWallpaper(path)
                }
            }

            IconTextButton {
                icon: "shuffle"
                text: qsTr("Ngẫu nhiên")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                type: IconTextButton.Tonal
                onClicked: {
                    Wallpapers.setRandom();
                    root.requestClose();
                }
            }
        }

        SystemDialogs.FileDialog {
            id: systemBrowseDialog

            title: qsTr("Chọn hình nền")
            currentFolder: Wallpapers.localFileUrl(Paths.wallsdir)
            nameFilters: [
                qsTr("Tệp hình nền (%1)").arg(Wallpapers.validWallpaperExtensions.map(extension => "*." + extension).join(" ")),
                qsTr("Tất cả tệp (*)")
            ]
            onAccepted: root.selectWallpaper(String(selectedFile))
        }

        ListView {
            id: wallList

            readonly property real itemWidth: 200
            readonly property real itemHeight: Math.round(itemWidth * 0.75) + 28

            Layout.fillWidth: true
            Layout.preferredHeight: itemHeight
            visible: Wallpapers.allWallpapers.length > 0

            orientation: ListView.Horizontal
            clip: true
            spacing: Tokens.spacing.large
            boundsBehavior: Flickable.StopAtBounds
            model: Wallpapers.allWallpapers

            delegate: WallItem {
                required property FileSystemEntry modelData

                width: wallList.itemWidth
                imgHeight: Math.round(width * 0.75)
                radius: Tokens.rounding.extraLarge
                source: String(modelData.path ?? "")
                text: modelData.name
                onClicked: root.selectWallpaper(modelData.path)
            }

            WheelHandler {
                // Let the usual vertical mouse wheel / touchpad scroll drive this
                // horizontal list too, since there's nothing to scroll vertically.
                target: null
                onWheel: event => {
                    const max = Math.max(0, wallList.contentWidth - wallList.width);
                    wallList.contentX = Math.max(0, Math.min(max, wallList.contentX - event.angleDelta.y));
                }
            }
        }

        Loader {
            Layout.fillWidth: true
            Layout.preferredHeight: wallList.itemHeight

            asynchronous: true
            active: Wallpapers.allWallpapers.length === 0
            visible: active

            sourceComponent: StyledRect {
                color: Colours.tPalette.m3surfaceContainer
                radius: Tokens.rounding.extraLarge

                ColumnLayout {
                    id: noWallsLayout

                    anchors.centerIn: parent
                    spacing: Tokens.spacing.extraSmall

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "hide_image"
                        color: Colours.palette.m3outline
                        fontStyle: Tokens.font.icon.extraLarge
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Không tìm thấy hình nền trong %1").arg(Paths.shortenHome(Paths.wallsdir))
                        color: Colours.palette.m3outline
                        font: Tokens.font.title.small
                    }
                }
            }
        }
    }

    function selectWallpaper(path: string): void {
        Wallpapers.setWallpaper(path);
        if (GlobalConfig.nexus.closeAfterWallpaperSelection)
            root.requestClose();
    }
}
