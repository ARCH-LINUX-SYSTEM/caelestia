import QtQuick
import QtMultimedia

Item {
    id: root

    property var _activeError: _usePlayerA ? playerA.error : playerB.error
    property string _activeErrorString: _usePlayerA ? playerA.errorString : playerB.errorString
    property int _activeMediaStatus: _usePlayerA ? playerA.mediaStatus : playerB.mediaStatus
    property int _activePlaybackState: _usePlayerA ? playerA.playbackState : playerB.playbackState
    property int _pendingSwapRequestId: 0

    // Deferred swap: store pending direction for the timer
    property bool _pendingSwapToA: true
    property int _requestId: 0

    // Prevent re-entrant swaps during load
    property bool _swapping: false

    // Internal: track which player is active (true = A, false = B)
    property bool _usePlayerA: true
    property bool autoStart: true
    property alias error: root._activeError
    property alias errorString: root._activeErrorString
    property bool forceFrameRenderA: false
    property bool forceFrameRenderB: false
    property bool hasRenderedFrame: false
    readonly property int loopLeadTime: 100
    property alias mediaStatus: root._activeMediaStatus

    // Expose active player state
    property alias playbackState: root._activePlaybackState
    property url videoSource

    function _executeDeferredSwap() {
        const requestId = _pendingSwapRequestId;
        const swapToA = _pendingSwapToA;
        const newPlayer = swapToA ? playerA : playerB;
        const oldPlayer = swapToA ? playerB : playerA;

        if (requestId !== _requestId || !sourceMatches(newPlayer)) {
            _swapping = false;
            return;
        }

        // Mark the incoming player active before starting it so its first frame
        // cannot be discarded by markFrameRendered().
        root._usePlayerA = swapToA;

        if (root.autoStart) {
            newPlayer.play();
        } else {
            if (swapToA)
                root.forceFrameRenderA = true;
            else
                root.forceFrameRenderB = true;
            newPlayer.play();
        }

        // Clean up old player source asynchronously
        const oldSource = sourceText(oldPlayer.source);
        Qt.callLater(() => {
            if (requestId !== root._requestId)
                return;
            if (root.sourceText(oldPlayer.source) === oldSource)
                root.setPlayerSource(oldPlayer, "");
            root._swapping = false;
        });
    }
    function _performSwap(swapToA) {
        const newPlayer = swapToA ? playerA : playerB;
        if (!sourceMatches(newPlayer))
            return;

        _swapping = true;
        _pendingSwapToA = swapToA;
        _pendingSwapRequestId = _requestId;

        // Pause old player immediately (frees Vulkan resources, <1ms)
        const oldPlayer = swapToA ? playerB : playerA;
        oldPlayer.pause();

        // Defer play() so picker UI gets time to render
        deferredPlayTimer.restart();
    }
    function hasVideoSource(): bool {
        return sourceText(videoSource) !== "";
    }
    function isActivePlayer(player): bool {
        return (_usePlayerA && player === playerA) || (!_usePlayerA && player === playerB);
    }
    function markFrameRendered(player): void {
        if (isActivePlayer(player) && sourceMatches(player))
            hasRenderedFrame = true;
    }
    function markPlaybackFailed(player): void {
        if (isActivePlayer(player) && sourceMatches(player))
            hasRenderedFrame = false;
    }
    function setPlayerSource(player, source): void {
        if (player === playerA)
            outputA.clearOutput();
        else
            outputB.clearOutput();
        player.source = source;
    }
    function pause() {
        // Note: _swapping selects the incoming player. If pause() is called during a swap,
        // it pauses the incoming video rather than the fading-out one.
        const active = _swapping ? (_pendingSwapToA ? playerA : playerB) : (_usePlayerA ? playerA : playerB);
        active.pause();
    }
    function play() {
        // Note: _swapping selects the incoming player. If play() is called during a swap,
        // it acts on the incoming video.
        const active = _swapping ? (_pendingSwapToA ? playerA : playerB) : (_usePlayerA ? playerA : playerB);
        if (hasVideoSource())
            active.play();
    }
    function restartNearEnd(player): void {
        if (!autoStart || _swapping || !isActivePlayer(player) || !sourceMatches(player))
            return;
        if (player.duration <= 0 || player.position <= 0)
            return;

        const leadTime = Math.min(loopLeadTime, Math.max(1, player.duration / 2));
        if (player.position < player.duration - leadTime)
            return;

        restartPlayer(player);
    }
    function restartPlayer(player): void {
        if (!autoStart || _swapping || !isActivePlayer(player) || !sourceMatches(player))
            return;

        const requestId = _requestId;
        player.stop();
        Qt.callLater(() => {
            if (requestId === root._requestId && root.autoStart && root.isActivePlayer(player) && root.sourceMatches(player))
                player.play();
        });
    }
    function sourceIsEmpty(player): bool {
        return sourceText(player.source) === "";
    }
    function sourceMatches(player): bool {
        return sourceText(player.source) === sourceText(videoSource);
    }
    function sourceText(source): string {
        return source ? source.toString() : "";
    }

    // No-op: clearing source handles cleanup.
    function stop() {
    }

    anchors.fill: parent

    Component.onCompleted: {
        if (hasVideoSource() && sourceIsEmpty(playerA) && sourceIsEmpty(playerB)) {
            setPlayerSource(playerA, videoSource);
            _usePlayerA = true;
        }
    }
    onVideoSourceChanged: {
        _requestId++;
        hasRenderedFrame = false;
        deferredPlayTimer.stop();
        _swapping = false;
        forceFrameRenderA = false;
        forceFrameRenderB = false;

        if (!hasVideoSource()) {
            setPlayerSource(playerA, "");
            setPlayerSource(playerB, "");
            return;
        }

        const activePlayer = _usePlayerA ? playerA : playerB;
        if (sourceMatches(activePlayer)) {
            if (root.autoStart) {
                activePlayer.play();
            } else {
                if (_usePlayerA)
                    forceFrameRenderA = true;
                else
                    forceFrameRenderB = true;
                activePlayer.play();
            }
            return;
        }

        if (sourceIsEmpty(playerA) && sourceIsEmpty(playerB)) {
            setPlayerSource(playerA, videoSource);
            _usePlayerA = true;
            return;
        }

        const inactivePlayer = _usePlayerA ? playerB : playerA;
        setPlayerSource(inactivePlayer, videoSource);
    }

    // ── Player A ──

    VideoOutput {
        id: outputA

        anchors.fill: parent
        endOfStreamPolicy: VideoOutput.KeepLastFrame
        fillMode: VideoOutput.PreserveAspectCrop
        visible: root._usePlayerA

        Connections {
            function onVideoFrameChanged() {
                root.markFrameRendered(playerA);
            }

            target: outputA.videoSink
        }
    }
    AudioOutput {
        id: mutedOutputA

        muted: true
        volume: 0
    }
    MediaPlayer {
        id: playerA

        audioOutput: mutedOutputA
        autoPlay: false
        loops: MediaPlayer.Once
        videoOutput: outputA

        onErrorOccurred: (error, errorString) => {
            if (error !== MediaPlayer.NoError) {
                console.warn("VideoPlayer A: error:", errorString);
                root.markPlaybackFailed(playerA);
            }
        }
        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.InvalidMedia) {
                console.warn("VideoPlayer A: invalid media:", playerA.source, playerA.errorString);
                root.markPlaybackFailed(playerA);
            } else if (mediaStatus === MediaPlayer.EndOfMedia) {
                root.restartPlayer(playerA);
            }

            // If this is the INCOMING player and it's ready, perform the swap
            if (!root._usePlayerA && !root._swapping && mediaStatus === MediaPlayer.LoadedMedia && root.sourceMatches(playerA)) {
                root._performSwap(true);
            }

            // First load: player A loaded and is already the active player
            if (root._usePlayerA && mediaStatus === MediaPlayer.LoadedMedia && root.sourceIsEmpty(playerB) && !root._swapping && root.sourceMatches(playerA)) {
                if (root.autoStart) {
                    playerA.play();
                } else {
                    root.forceFrameRenderA = true;
                    playerA.play();
                }
            }
        }
        onPositionChanged: {
            if (root.forceFrameRenderA && playerA.position > 0) {
                root.forceFrameRenderA = false;
                playerA.pause();
            } else {
                root.restartNearEnd(playerA);
            }
        }
    }

    // ── Player B ──

    VideoOutput {
        id: outputB

        anchors.fill: parent
        endOfStreamPolicy: VideoOutput.KeepLastFrame
        fillMode: VideoOutput.PreserveAspectCrop
        visible: !root._usePlayerA

        Connections {
            function onVideoFrameChanged() {
                root.markFrameRendered(playerB);
            }

            target: outputB.videoSink
        }
    }
    AudioOutput {
        id: mutedOutputB

        muted: true
        volume: 0
    }
    MediaPlayer {
        id: playerB

        audioOutput: mutedOutputB
        autoPlay: false
        loops: MediaPlayer.Once
        videoOutput: outputB

        onErrorOccurred: (error, errorString) => {
            if (error !== MediaPlayer.NoError) {
                console.warn("VideoPlayer B: error:", errorString);
                root.markPlaybackFailed(playerB);
            }
        }
        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.InvalidMedia) {
                console.warn("VideoPlayer B: invalid media:", playerB.source, playerB.errorString);
                root.markPlaybackFailed(playerB);
            } else if (mediaStatus === MediaPlayer.EndOfMedia) {
                root.restartPlayer(playerB);
            }

            // If this is the INCOMING player and it's ready, perform the swap
            if (root._usePlayerA && !root._swapping && mediaStatus === MediaPlayer.LoadedMedia && root.sourceMatches(playerB)) {
                root._performSwap(false);
            }
        }
        onPositionChanged: {
            if (root.forceFrameRenderB && playerB.position > 0) {
                root.forceFrameRenderB = false;
                playerB.pause();
            } else {
                root.restartNearEnd(playerB);
            }
        }
    }

    // Timer to defer play() so the picker UI can process click feedback
    // before the main thread blocks on FFmpeg/Vulkan initialization (~2s).
    Timer {
        id: deferredPlayTimer

        interval: 100  // ~6 frames at 60fps — enough for picker click feedback
        repeat: false

        onTriggered: root._executeDeferredSwap()
    }
}
