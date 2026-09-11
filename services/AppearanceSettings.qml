import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.utils

Scope {
    id: root

    property bool cliLoaded
    property var cliData: ({})

    function clamp(value, minimum = 0, maximum = 1) {
        return Math.max(minimum, Math.min(maximum, value));
    }

    function paletteVariant(type: string): string {
        const variants = {
            "scheme-content": "content",
            "scheme-expressive": "expressive",
            "scheme-fidelity": "fidelity",
            "scheme-fruit-salad": "fruitsalad",
            "scheme-monochrome": "monochrome",
            "scheme-neutral": "neutral",
            "scheme-rainbow": "rainbow",
            "scheme-tonal-spot": "tonalspot"
        };
        return variants[type] ?? "";
    }

    function requestPaletteApply(): void {
        const desired = paletteVariant(GlobalConfig.appearance.palette.type);
        if (desired && desired !== Colours.variant)
            paletteTimer.restart();
    }

    function requestCliSync(): void {
        if (GlobalConfig.appearance.wallpaperTheming.managed && cliLoaded)
            cliSyncTimer.restart();
    }

    function syncCliConfig(): void {
        if (!GlobalConfig.appearance.wallpaperTheming.managed || !cliLoaded)
            return;

        const data = Object.assign({}, cliData);
        const theme = Object.assign({}, data.theme ?? {});
        const config = GlobalConfig.appearance.wallpaperTheming;

        theme.enableHypr = config.enableAppsAndShell;
        theme.enableGtk = config.enableAppsAndShell;
        theme.enableQt = config.enableQtApps;
        theme.enableTerm = config.enableTerminal;
        data.theme = theme;

        const text = JSON.stringify(data, null, 2) + "\n";
        cliData = data;
        if (cliFile.text() !== text)
            cliFile.setText(text);

        if (config.enableTerminal)
            requestTerminalApply();
        reapplyTimer.restart();
    }

    function handleCliLoaded(text: string): void {
        try {
            const parsed = text.trim() ? JSON.parse(text) : {};
            if (!parsed || typeof parsed !== "object" || Array.isArray(parsed))
                throw new Error("root must be an object");
            cliData = parsed;
            cliLoaded = true;
            requestCliSync();
        } catch (error) {
            cliLoaded = false;
            console.warn("AppearanceSettings: refusing to overwrite invalid Caelestia CLI config:", error);
        }
    }

    function hexChannel(value: real): string {
        return Math.round(clamp(value) * 255).toString(16).padStart(2, "0");
    }

    function rgbParts(colour: color): string {
        return `${hexChannel(colour.r)}/${hexChannel(colour.g)}/${hexChannel(colour.b)}`;
    }

    function osc(index: int, colour: color): string {
        return `\x1b]${index};rgb:${rgbParts(colour)}\x1b\\`;
    }

    function paletteOsc(index: int, colour: color): string {
        return `\x1b]4;${index};rgb:${rgbParts(colour)}\x1b\\`;
    }

    function harmonise(source: color, accent: color, darkMode: bool): color {
        const props = GlobalConfig.appearance.wallpaperTheming.terminalGenerationProps;
        if (GlobalConfig.appearance.palette.type === "scheme-monochrome")
            return source;

        const sourceHue = source.hslHue < 0 ? accent.hslHue : source.hslHue;
        const accentHue = accent.hslHue < 0 ? sourceHue : accent.hslHue;
        let difference = ((accentHue - sourceHue + 1.5) % 1) - 0.5;
        const rotation = Math.min(Math.abs(difference) * 360 * props.harmony, props.harmonizeThreshold) / 360;
        const hue = (sourceHue + Math.sign(difference) * rotation + 1) % 1;
        const toneFactor = 1 + props.termFgBoost * (darkMode ? 1 : -1);
        return Qt.hsla(hue, source.hslSaturation, clamp(source.hslLightness * toneFactor), 1);
    }

    function terminalSequence(): string {
        const colours = Colours.current;
        const props = GlobalConfig.appearance.wallpaperTheming.terminalGenerationProps;
        const darkMode = props.forceDarkMode || !Colours.currentLight;
        const background = darkMode && Colours.currentLight ? colours.m3inverseSurface : colours.m3surfaceContainerLow;
        const foreground = darkMode && Colours.currentLight ? colours.m3inverseOnSurface : colours.m3onSurface;
        const accent = colours.m3primary_paletteKeyColor;
        const terms = [];

        for (let index = 0; index < 16; index++) {
            if (index === 0)
                terms.push(background);
            else if (index === 15)
                terms.push(foreground);
            else
                terms.push(harmonise(colours[`term${index}`], accent, darkMode));
        }

        let output = osc(10, foreground) + osc(11, background) + osc(12, colours.m3secondary) + osc(17, colours.m3secondary);
        for (let index = 0; index < terms.length; index++)
            output += paletteOsc(index, terms[index]);
        output += paletteOsc(16, colours.m3primary) + paletteOsc(17, colours.m3secondary) + paletteOsc(18, colours.m3tertiary);
        return output;
    }

    function requestTerminalApply(): void {
        const config = GlobalConfig.appearance.wallpaperTheming;
        if (config.managed && config.enableTerminal)
            terminalTimer.restart();
    }

    function broadcastTerminal(): void {
        Quickshell.execDetached([
            "sh",
            "-c",
            "for file in /dev/pts/[0-9]*; do [ -w \"$file\" ] && cat \"$1\" > \"$file\" || true; done",
            "caelestia-terminal-theme",
            `${Paths.state}/sequences.txt`
        ]);
    }

    Component.onCompleted: requestPaletteApply()

    Connections {
        function onTypeChanged(): void {
            root.requestPaletteApply();
        }

        target: GlobalConfig.appearance.palette
    }

    Connections {
        function onManagedChanged(): void {
            root.requestCliSync();
        }

        function onEnableAppsAndShellChanged(): void {
            root.requestCliSync();
        }

        function onEnableQtAppsChanged(): void {
            root.requestCliSync();
        }

        function onEnableTerminalChanged(): void {
            root.requestCliSync();
        }

        target: GlobalConfig.appearance.wallpaperTheming
    }

    Connections {
        function onForceDarkModeChanged(): void {
            root.requestTerminalApply();
        }

        function onHarmonizeThresholdChanged(): void {
            root.requestTerminalApply();
        }

        function onHarmonyChanged(): void {
            root.requestTerminalApply();
        }

        function onTermFgBoostChanged(): void {
            root.requestTerminalApply();
        }

        target: GlobalConfig.appearance.wallpaperTheming.terminalGenerationProps
    }

    Connections {
        function onSchemeLoaded(): void {
            root.requestPaletteApply();
            root.requestTerminalApply();
        }

        target: Colours
    }

    FileView {
        id: cliFile

        path: `${Paths.config}/cli.json`
        printErrors: false
        watchChanges: true

        onFileChanged: reload()
        onLoaded: root.handleCliLoaded(text())
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.cliData = {};
                root.cliLoaded = true;
                root.requestCliSync();
            }
        }
    }

    FileView {
        id: terminalFile

        path: `${Paths.state}/sequences.txt`
        printErrors: false
        atomicWrites: true
        onSaved: root.broadcastTerminal()
    }

    Timer {
        id: paletteTimer

        interval: 120
        onTriggered: {
            const desired = root.paletteVariant(GlobalConfig.appearance.palette.type);
            if (desired && desired !== Colours.variant)
                Quickshell.execDetached(["caelestia", "scheme", "set", "--notify", "-v", desired]);
        }
    }

    Timer {
        id: cliSyncTimer

        interval: 120
        onTriggered: root.syncCliConfig()
    }

    Timer {
        id: reapplyTimer

        interval: 220
        onTriggered: {
            const variant = root.paletteVariant(GlobalConfig.appearance.palette.type) || Colours.variant || "tonalspot";
            Quickshell.execDetached(["caelestia", "scheme", "set", "--notify", "-v", variant]);
        }
    }

    Timer {
        id: terminalTimer

        interval: 160
        onTriggered: terminalFile.setText(root.terminalSequence())
    }
}
