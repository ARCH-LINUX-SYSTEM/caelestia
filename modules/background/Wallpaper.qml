pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.filedialog
import qs.components.images
import qs.services
import qs.utils

Item {
    id: root

    property bool completed
    property Image current: one
    readonly property bool centered: Config.background.centeredWallpaper && (!Config.background.centeredWallpaperOnlyWhenLocked || ShellState.locked)
    readonly property real centeredExtent: Math.min(Config.background.centeredWallpaperSize, width, height)
    readonly property real wallpaperWidth: centered ? centeredExtent : width
    readonly property real wallpaperHeight: centered ? centeredExtent : height
    readonly property url gifSource: sourceIsGif ? toFileUrl(source) : ""
    readonly property string configuredSource: Config.background.wallpaperPath.trim() ? Paths.absolutePath(Config.background.wallpaperPath.trim()) : ""
    property string source: configuredSource || Wallpapers.current
    readonly property bool sourceIsGif: Wallpapers.isGif(source)
    readonly property bool sourceIsVideo: Wallpapers.isVideo(source)
    readonly property url videoSource: sourceIsVideo ? toFileUrl(source) : ""
    readonly property bool videoShouldPlay: (Config.background.videoWallpaperAutoplay ?? true) && !WallpaperPauser.paused

    function centeredColour(): color {
        const configured = Config.background.centeredWallpaperColor;
        const paletteName = configured.startsWith("m3") ? configured : "m3" + configured.slice(0, 1).toUpperCase() + configured.slice(1);
        return Colours.palette[paletteName] ?? Colours.palette.m3surface;
    }

    function toFileUrl(path) {
        const clean = Wallpapers.localPath(path);

        if (!clean)
            return "";
        if (clean[0] === "/") {
            return "file://" + clean.split("/").map(segment => encodeURIComponent(segment)).join("/");
        }

        return Qt.resolvedUrl(clean);
    }

    function updateVideoPreview(): void {
        if (!sourceIsVideo)
            return;

        const preview = current === one ? two : one;
        preview.update();
    }

    Component.onCompleted: {
        if (sourceIsVideo) {
            one.update();
            completed = true;
        } else if (source) {
            Qt.callLater(() => {
                one.update();
                completed = true;
            });
        }
    }

    onSourceChanged: {
        if (sourceIsVideo) {
            const previous = current;
            current = null;
            videoUpdateTimer.restart();

            if (previous === one)
                two.update();
            else
                one.update();
        } else if (!source) {
            current = null;
        } else if (current === one) {
            two.update();
        } else {
            one.update();
        }
    }

    Timer {
        id: videoUpdateTimer

        interval: 200
        repeat: false

        onTriggered: {
            if (videoLoader.video && root.sourceIsVideo) {
                videoLoader.video.videoSource = root.videoSource;
                videoLoader.video.autoStart = root.videoShouldPlay;
            }
        }
    }

    Connections {
        function onPausedChanged() {
            if (videoLoader.video && root.sourceIsVideo) {
                videoLoader.video.autoStart = root.videoShouldPlay;
                if (root.videoShouldPlay) {
                    videoLoader.video.play();
                } else {
                    videoLoader.video.pause();
                }
            }
        }

        ignoreUnknownSignals: true
        target: WallpaperPauser
    }

    Connections {
        function onVideoWallpaperAutoplayChanged() {
            if (videoLoader.video && root.sourceIsVideo) {
                videoLoader.video.autoStart = root.videoShouldPlay;
                if (root.videoShouldPlay) {
                    videoLoader.video.play();
                } else {
                    videoLoader.video.pause();
                }
            }
        }

        ignoreUnknownSignals: true
        target: Config.background
    }

    Connections {
        function onCacheBusterChanged() {
            root.updateVideoPreview();
        }
        function onItemBustersChanged() {
            root.updateVideoPreview();
        }

        target: Wallpapers
    }

    Rectangle {
        anchors.fill: parent
        visible: root.centered
        color: root.centeredColour()
    }

    Loader {
        active: root.completed && !root.source
        anchors.fill: parent
        asynchronous: true

        sourceComponent: StyledRect {
            color: Colours.palette.m3surfaceContainer

            Row {
                anchors.centerIn: parent
                spacing: Tokens.spacing.largeIncreased

                MaterialIcon {
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.builders.extraLarge.scale(5).build()
                    text: "sentiment_stressed"
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.spacing.small

                    StyledText {
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.builders.large.size(28 * 2).weight(Font.Bold).build()
                        text: qsTr("Thiếu hình nền?")
                    }
                    StyledRect {
                        color: Colours.palette.m3primary
                        implicitHeight: selectWallText.implicitHeight + Tokens.padding.small
                        implicitWidth: selectWallText.implicitWidth + Tokens.padding.extraLargeIncreased
                        radius: Tokens.rounding.full

                        FileDialog {
                            id: dialog

                            filterLabel: qsTr("Tệp hình ảnh và video")
                            filters: Wallpapers.validWallpaperExtensions
                            targetScreen: (root.QsWindow.window as QsWindow)?.screen
                            title: qsTr("Chọn hình nền")

                            onAccepted: path => Wallpapers.setWallpaper(path)
                        }
                        StateLayer {
                            color: Colours.palette.m3onPrimary
                            radius: parent.radius

                            onClicked: dialog.open()
                        }
                        StyledText {
                            id: selectWallText

                            anchors.centerIn: parent
                            color: Colours.palette.m3onPrimary
                            font: Tokens.font.body.large
                            text: qsTr("Đặt ngay!")
                        }
                    }
                }
            }
        }
    }

    Img {
        id: one
    }
    Img {
        id: two
    }
    Loader {
        id: videoLoader

        readonly property VideoWallpaper video: item as VideoWallpaper

        active: root.sourceIsVideo
        anchors.centerIn: parent
        width: root.wallpaperWidth
        height: root.wallpaperHeight
        source: "VideoWallpaper.qml"

        onLoaded: {
            if (!video)
                return;

            video.autoStart = root.videoShouldPlay;
            video.videoSource = root.videoSource;
        }
    }
    AnimatedImage {
        id: gifWallpaper

        anchors.centerIn: parent
        width: root.wallpaperWidth
        height: root.wallpaperHeight
        asynchronous: true
        cache: false
        fillMode: Image.PreserveAspectCrop
        paused: WallpaperPauser.paused
        playing: root.sourceIsGif
        source: root.gifSource
        visible: root.sourceIsGif && status === Image.Ready
    }

    component Img: CachingImage {
        id: img

        function update(): void {
            const thumbnailBuster = Wallpapers.itemBusters[root.source] || Wallpapers.cacheBuster;
            const configuredThumbnail = Config.background.thumbnailPath.trim() ? Paths.absolutePath(Config.background.thumbnailPath.trim()) : "";
            const newPath = root.sourceIsVideo ? (configuredThumbnail || Wallpapers.getWallpaperThumb(root.source, thumbnailBuster)) : root.source;

            if (!root.sourceIsVideo && path === root.source) {
                root.current = this;
                return;
            }

            if (root.sourceIsVideo && path === root.source && source === newPath) {
                root.current = this;
                return;
            }

            path = root.source;
            source = newPath;
        }

        anchors.centerIn: parent
        width: root.wallpaperWidth
        height: root.wallpaperHeight
        opacity: 0
        scale: Wallpapers.showPreview ? 1 : 0.8
        visible: !root.sourceIsVideo || !videoLoader.video || !videoLoader.video.hasRenderedFrame

        states: State {
            name: "visible"
            when: root.current === img

            PropertyChanges {
                img.opacity: 1
                img.scale: 1
            }
        }
        transitions: Transition {
            Anim {
                properties: "opacity,scale"
                target: img
            }
        }

        onStatusChanged: {
            if (status === Image.Ready)
                root.current = this;
        }
    }
}
