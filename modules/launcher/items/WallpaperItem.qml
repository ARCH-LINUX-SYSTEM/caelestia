import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.Images
import Caelestia.Models
import qs.components
import qs.components.effects
import qs.components.images
import qs.services

Item {
    id: root

    required property FileSystemEntry modelData
    required property ScreenState screenState

    implicitHeight: image.height + label.height + Tokens.spacing.extraSmall + Tokens.padding.large + Tokens.padding.medium
    implicitWidth: image.width + Tokens.padding.medium * 2
    opacity: PathView.onPath ? 1 : 0
    scale: PathView.isCurrentItem ? 1 : PathView.onPath ? 0.8 : 0
    z: PathView.z ?? 0 // qmllint disable missing-property

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }
    Behavior on scale {
        Anim {}
    }

    Item {
        id: popContainer

        anchors.fill: parent

        StateLayer {
            anchors.fill: parent
            radius: Tokens.rounding.large

            onClicked: {
                Wallpapers.setWallpaper(root.modelData.path);
                root.screenState.launcher = false;
            }
        }
        Elevation {
            anchors.fill: image
            level: 4
            opacity: root.PathView.isCurrentItem ? 1 : 0
            radius: image.radius

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }
        StyledClippingRect {
            id: image

            anchors.horizontalCenter: parent.horizontalCenter
            color: Colours.tPalette.m3surfaceContainer
            implicitHeight: implicitWidth / 16 * 9
            implicitWidth: Tokens.sizes.launcher.wallpaperWidth
            radius: Tokens.rounding.large
            y: Tokens.padding.large

            MaterialIcon {
                anchors.centerIn: parent
                color: Colours.tPalette.m3outline
                fontStyle: Tokens.font.icon.builders.extraLarge.scale(2).weight(Font.DemiBold).build()
                text: "image"
            }
            CachingImage {
                id: thumbImg

                readonly property bool isThumbReady: !Wallpapers._refreshing || Wallpapers.itemBusters[root.modelData.path] !== undefined

                anchors.fill: parent
                opacity: isThumbReady && status === Image.Ready ? 1 : 0
                path: root.modelData.path
                scale: isThumbReady && status === Image.Ready ? 1 : 0.7
                smooth: !root.PathView.view?.moving ?? true
                source: Wallpapers.isVideo(root.modelData.path) ? Wallpapers.getWallpaperThumb(root.modelData.path, Wallpapers.itemBusters[root.modelData.path] || Wallpapers.cacheBuster) : IUtils.urlForPath(root.modelData.path, fillMode)
                sourceSize: {
                    const dpr = (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1;
                    return Qt.size(image.implicitWidth * dpr, image.implicitHeight * dpr);
                }

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
                Behavior on scale {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }

            Loader {
                anchors.fill: parent
                active: Wallpapers.isVideo(root.modelData.path)
                asynchronous: true

                sourceComponent: LiveVideoPreview {
                    source: Wallpapers.localFileUrl(root.modelData.path)
                }
            }
        }
        StyledText {
            id: label

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: image.bottom
            anchors.topMargin: Tokens.spacing.extraSmall
            elide: Text.ElideRight
            font: Tokens.font.label.medium
            horizontalAlignment: Text.AlignHCenter
            renderType: Text.QtRendering
            text: root.modelData.relativePath
            width: image.width - Tokens.padding.medium * 2
        }
    }
}
