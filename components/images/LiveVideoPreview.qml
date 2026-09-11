import QtQuick
import QtMultimedia
import qs.components

Item {
    id: root

    property url source
    property int fillMode: VideoOutput.PreserveAspectCrop
    readonly property bool hasFrame: player.hasRenderedFrame

    function hasSource(): bool {
        return source.toString() !== "";
    }

    VideoOutput {
        id: videoOutput

        anchors.fill: parent
        fillMode: root.fillMode
        opacity: root.hasFrame ? 1 : 0

        Behavior on opacity {
            Anim {
                type: Anim.SlowEffects
            }
        }

        Connections {
            function onVideoFrameChanged() {
                player.hasRenderedFrame = true;
            }

            target: videoOutput.videoSink
        }
    }

    AudioOutput {
        id: mutedOutput

        muted: true
        volume: 0
    }

    MediaPlayer {
        id: player

        property bool hasRenderedFrame: false

        audioOutput: mutedOutput
        loops: MediaPlayer.Infinite
        source: root.hasSource() ? root.source : ""
        videoOutput: videoOutput

        onSourceChanged: hasRenderedFrame = false
        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.LoadedMedia && playbackState !== MediaPlayer.PlayingState)
                play();
        }
    }
}
