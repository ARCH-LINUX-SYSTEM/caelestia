pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Caelestia
import Caelestia.Config
import Caelestia.Services

Singleton {
    id: root

    property string previousSinkName: ""
    property string previousSourceName: ""
    property real lastSafeOutputVolume: NaN
    property real expectedOutputVolume: NaN
    readonly property real outputVolumeEpsilon: 0.0005

    property list<PwNode> sinks: []
    property list<PwNode> sources: []
    property list<PwNode> streams: []

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property bool muted: !!sink?.audio?.muted
    readonly property real volume: sink?.audio?.volume ?? 0

    readonly property bool sourceMuted: !!source?.audio?.muted
    readonly property real sourceVolume: source?.audio?.volume ?? 0

    readonly property alias cava: cava
    readonly property alias beatTracker: beatTracker

    function outputVolumesClose(a: real, b: real): bool {
        return Math.abs(a - b) <= outputVolumeEpsilon;
    }

    function resetOutputProtection(): void {
        expectedOutputVolume = NaN;
        lastSafeOutputVolume = sink?.ready && sink?.audio ? volume : NaN;
    }

    function writeOutputVolume(newVolume: real, allowJump: bool): void {
        if (!sink?.ready || !sink?.audio)
            return;

        const target = Math.max(0, Math.min(GlobalConfig.services.maxVolume, newVolume));
        sink.audio.muted = false;
        if (outputVolumesClose(volume, target)) {
            lastSafeOutputVolume = target;
            expectedOutputVolume = NaN;
            return;
        }

        expectedOutputVolume = allowJump && GlobalConfig.services.audioProtection.enabled ? target : NaN;
        sink.audio.volume = target;
    }

    function enforceOutputVolume(target: real, title: string, message: string): void {
        if (!sink?.ready || !sink?.audio)
            return;

        const safeTarget = Math.max(0, Math.min(GlobalConfig.services.maxVolume, target));
        expectedOutputVolume = safeTarget;
        sink.audio.volume = safeTarget;
        Toaster.toast(title, message, "hearing");
    }

    function handleOutputVolumeChanged(): void {
        const newVolume = volume;
        if (isNaN(newVolume) || !isFinite(newVolume)) {
            resetOutputProtection();
            return;
        }

        if (!GlobalConfig.services.audioProtection.enabled) {
            lastSafeOutputVolume = newVolume;
            expectedOutputVolume = NaN;
            return;
        }

        if (!isNaN(expectedOutputVolume)) {
            if (outputVolumesClose(newVolume, expectedOutputVolume)) {
                lastSafeOutputVolume = newVolume;
                expectedOutputVolume = NaN;
                return;
            }
            expectedOutputVolume = NaN;
        }

        if (isNaN(lastSafeOutputVolume) || !isFinite(lastSafeOutputVolume)) {
            lastSafeOutputVolume = newVolume;
            return;
        }

        const maxVolume = Math.max(0, GlobalConfig.services.maxVolume);
        const maxIncrease = Math.max(0, GlobalConfig.services.audioProtection.maxIncrease);
        if (newVolume > maxVolume + outputVolumeEpsilon) {
            enforceOutputVolume(Math.min(lastSafeOutputVolume, maxVolume), qsTr("Đã giới hạn âm lượng"), qsTr("Âm lượng đầu ra vượt quá giới hạn đã cấu hình"));
        } else if (newVolume - lastSafeOutputVolume > maxIncrease + outputVolumeEpsilon) {
            enforceOutputVolume(lastSafeOutputVolume, qsTr("Đã chặn tăng âm lượng"), qsTr("Phát hiện mức tăng âm lượng đột ngột từ ứng dụng bên ngoài"));
        } else {
            lastSafeOutputVolume = newVolume;
        }
    }

    function setVolume(newVolume: real): void {
        writeOutputVolume(newVolume, true);
    }

    function incrementVolume(amount: real): void {
        setVolume(volume + (amount || GlobalConfig.services.audioIncrement));
    }

    function decrementVolume(amount: real): void {
        setVolume(volume - (amount || GlobalConfig.services.audioIncrement));
    }

    function setSourceVolume(newVolume: real): void {
        if (source?.ready && source?.audio) {
            source.audio.muted = false;
            source.audio.volume = Math.max(0, Math.min(GlobalConfig.services.maxVolume, newVolume));
        }
    }

    function incrementSourceVolume(amount: real): void {
        setSourceVolume(sourceVolume + (amount || GlobalConfig.services.audioIncrement));
    }

    function decrementSourceVolume(amount: real): void {
        setSourceVolume(sourceVolume - (amount || GlobalConfig.services.audioIncrement));
    }

    function setAudioSink(newSink: PwNode): void {
        Pipewire.preferredDefaultAudioSink = newSink;
    }

    function setAudioSource(newSource: PwNode): void {
        Pipewire.preferredDefaultAudioSource = newSource;
    }

    function cycleNextAudioOutput(): void {
        if (sinks.length === 0)
            return;

        const currentIndex = sinks.findIndex(s => s === sink);
        const nextIndex = (currentIndex + 1) % sinks.length;
        setAudioSink(sinks[nextIndex]);
    }

    function setStreamVolume(stream: PwNode, newVolume: real): void {
        if (stream?.ready && stream?.audio) {
            stream.audio.muted = false;
            stream.audio.volume = Math.max(0, Math.min(GlobalConfig.services.maxVolume, newVolume));
        }
    }

    function setStreamMuted(stream: PwNode, muted: bool): void {
        if (stream?.ready && stream?.audio) {
            stream.audio.muted = muted;
        }
    }

    function getStreamVolume(stream: PwNode): real {
        return stream?.audio?.volume ?? 0;
    }

    function getStreamMuted(stream: PwNode): bool {
        return !!stream?.audio?.muted;
    }

    function getStreamName(stream: PwNode): string {
        if (!stream)
            return qsTr("Không rõ");
        // Try application name first, then description, then name
        return stream.properties["application.name"] || stream.description || stream.name || qsTr("Ứng dụng không rõ");
    }

    function refreshNodes(): void {
        const newSinks = [];
        const newSources = [];
        const newStreams = [];

        for (const node of Pipewire.nodes.values) {
            if (!node.isStream) {
                if (node.isSink)
                    newSinks.push(node);
                else if (node.audio)
                    newSources.push(node);
            } else if (node.audio) {
                newStreams.push(node);
            }
        }

        root.sinks = newSinks;
        root.sources = newSources;
        root.streams = newStreams;
    }

    onSinkChanged: {
        resetOutputProtection();

        if (!sink?.ready)
            return;

        const newSinkName = sink.description || sink.name || qsTr("Thiết bị không rõ");

        if (previousSinkName && previousSinkName !== newSinkName && GlobalConfig.utilities.toasts.audioOutputChanged)
            Toaster.toast(qsTr("Đã đổi đầu ra âm thanh"), qsTr("Hiện đang dùng: %1").arg(newSinkName), "volume_up");

        previousSinkName = newSinkName;
    }

    onSourceChanged: {
        if (!source?.ready)
            return;

        const newSourceName = source.description || source.name || qsTr("Thiết bị không rõ");

        if (previousSourceName && previousSourceName !== newSourceName && GlobalConfig.utilities.toasts.audioInputChanged)
            Toaster.toast(qsTr("Đã đổi đầu vào âm thanh"), qsTr("Hiện đang dùng: %1").arg(newSourceName), "mic");

        previousSourceName = newSourceName;
    }

    // Populate immediately: Pipewire.nodes may already be filled by the time this
    // lazily-loaded singleton is created, so onValuesChanged would never fire.
    Component.onCompleted: {
        refreshNodes();
        previousSinkName = sink?.description || sink?.name || qsTr("Thiết bị không rõ");
        previousSourceName = source?.description || source?.name || qsTr("Thiết bị không rõ");
        resetOutputProtection();
    }

    Connections {
        function onVolumeChanged(): void {
            root.handleOutputVolumeChanged();
        }

        target: root.sink?.audio ?? null
    }

    Connections {
        function onEnabledChanged(): void {
            root.resetOutputProtection();
            if (GlobalConfig.services.audioProtection.enabled && root.volume > GlobalConfig.services.maxVolume)
                root.enforceOutputVolume(GlobalConfig.services.maxVolume, qsTr("Đã giới hạn âm lượng"), qsTr("Âm lượng đầu ra vượt quá giới hạn đã cấu hình"));
        }

        function onMaxIncreaseChanged(): void {
            root.resetOutputProtection();
        }

        target: GlobalConfig.services.audioProtection
    }

    Connections {
        function onMaxVolumeChanged(): void {
            if (GlobalConfig.services.audioProtection.enabled && root.volume > GlobalConfig.services.maxVolume)
                root.enforceOutputVolume(GlobalConfig.services.maxVolume, qsTr("Đã giới hạn âm lượng"), qsTr("Âm lượng đầu ra vượt quá giới hạn đã cấu hình"));
            else
                root.resetOutputProtection();
        }

        target: GlobalConfig.services
    }

    Connections {
        function onValuesChanged(): void {
            root.refreshNodes();
        }

        target: Pipewire.nodes
    }

    // Always track the current defaults so volume/mute bind even if the lists
    // momentarily lag behind the default node.
    PwObjectTracker {
        objects: [root.sink, root.source, ...root.sinks, ...root.sources, ...root.streams].filter(n => n)
    }

    CavaProvider {
        id: cava

        bars: GlobalConfig.services.visualiserBars
    }

    BeatTracker {
        id: beatTracker
    }

    IpcHandler {
        function cycleOutput(): void {
            root.cycleNextAudioOutput();
        }

        target: "audio"
    }
}
