pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config

Singleton {
    id: root

    readonly property bool ready: true
    readonly property bool enabled: GlobalConfig.hyprland.enabled
    property var autostartQueue: []
    property int autostartIndex

    function animationPreset(name: string): var {
        const presets = {
            fast: {
                curves: [
                    ["pc_wobble", 0.15, 1.15, 0.35, 1],
                    ["pc_decel", 0.05, 0.9, 0.1, 1.05],
                    ["pc_accel", 0.3, 0, 0.8, 0.15]
                ],
                animations: [
                    ["windowsIn", 5, "pc_wobble", "slide"],
                    ["windowsOut", 5, "pc_accel", "slide"],
                    ["windowsMove", 5, "pc_decel", "slide"],
                    ["fadeIn", 4, "pc_decel", ""],
                    ["fadeOut", 4, "pc_accel", ""],
                    ["layersIn", 4, "pc_decel", "slide"],
                    ["layersOut", 4, "pc_accel", "slide"],
                    ["workspaces", 6, "pc_decel", "slide"],
                    ["specialWorkspaceIn", 2, "pc_wobble", "slidevert"],
                    ["specialWorkspaceOut", 2, "pc_accel", "slidevert"]
                ]
            },
            normal: {
                curves: [
                    ["emphasizedDecel", 0.05, 0.7, 0.1, 1],
                    ["emphasizedAccel", 0.3, 0, 0.8, 0.15],
                    ["menu_decel", 0.1, 1, 0, 1],
                    ["menu_accel", 0.52, 0.03, 0.72, 0.08],
                    ["stall", 1, -0.1, 0.7, 0.85]
                ],
                animations: [
                    ["windowsIn", 3, "emphasizedDecel", "popin 80%"],
                    ["windowsOut", 2, "emphasizedDecel", "popin 90%"],
                    ["windowsMove", 3, "emphasizedDecel", "slide"],
                    ["fadeIn", 3, "emphasizedDecel", ""],
                    ["fadeOut", 2, "emphasizedDecel", ""],
                    ["border", 10, "emphasizedDecel", ""],
                    ["layersIn", 2.7, "emphasizedDecel", "popin 93%"],
                    ["layersOut", 2.4, "menu_accel", "popin 94%"],
                    ["fadeLayersIn", 0.5, "menu_decel", ""],
                    ["fadeLayersOut", 2.7, "stall", ""],
                    ["workspaces", 7, "menu_decel", "slide"],
                    ["specialWorkspaceIn", 2.8, "emphasizedDecel", "slidevert"],
                    ["specialWorkspaceOut", 1.2, "emphasizedAccel", "slidevert"]
                ]
            },
            niri: {
                curves: [
                    ["niri_wobble", 0.15, 1.15, 0.35, 1],
                    ["niri_decel", 0.05, 0.9, 0.1, 1.05],
                    ["niri_accel", 0.3, 0, 0.8, 0.15]
                ],
                animations: [
                    ["windowsIn", 5, "niri_wobble", "slide"],
                    ["windowsOut", 5, "niri_accel", "slide"],
                    ["windowsMove", 5, "niri_decel", "slide"],
                    ["fadeIn", 4, "niri_decel", ""],
                    ["fadeOut", 4, "niri_accel", ""],
                    ["layersIn", 4, "niri_decel", "slide"],
                    ["layersOut", 4, "niri_accel", "slide"],
                    ["workspaces", 6, "niri_decel", "slidevert"],
                    ["specialWorkspaceIn", 4, "niri_wobble", "slidevert"],
                    ["specialWorkspaceOut", 4, "niri_accel", "slidevert"]
                ]
            }
        };
        return presets[name] ?? presets.normal;
    }

    function animationPresetMessages(name: string): list<string> {
        const preset = animationPreset(name);
        const messages = [];
        for (const curve of preset.curves) {
            if (Hypr.usingLua)
                messages.push(`eval hl.curve("${curve[0]}", { type = "bezier", points = { {${curve[1]}, ${curve[2]}}, {${curve[3]}, ${curve[4]}} } })`);
            else
                messages.push(`keyword bezier ${curve[0]}, ${curve[1]}, ${curve[2]}, ${curve[3]}, ${curve[4]}`);
        }
        for (const animation of preset.animations) {
            const style = animation[3];
            if (Hypr.usingLua)
                messages.push(`eval hl.animation({ leaf = "${animation[0]}", enabled = true, speed = ${animation[1]}, bezier = "${animation[2]}"${style ? `, style = "${style}"` : ""} })`);
            else
                messages.push(`keyword animation ${animation[0]}, 1, ${animation[1]}, ${animation[2]}${style ? `, ${style}` : ""}`);
        }
        return messages;
    }

    function normaliseAutostartEntry(entry: var): var {
        if (typeof entry === "string")
            return {
                command: entry.trim(),
                workspace: 0,
                delay: 0
            };
        if (!entry || typeof entry !== "object" || Array.isArray(entry))
            return null;
        return {
            command: String(entry.command ?? entry.cmd ?? "").trim(),
            workspace: Math.max(0, Math.round(Number(entry.workspace ?? 0))),
            delay: Math.max(0, Number(entry.delay ?? 0))
        };
    }

    function launchAutostartEntry(entry: var): void {
        if (!entry?.command)
            return;
        if (entry.workspace > 0) {
            Quickshell.execDetached(["hyprctl", "dispatch", "exec", `[workspace ${entry.workspace} silent] ${entry.command}`]);
        } else {
            Quickshell.execDetached(["sh", "-lc", entry.command]);
        }
    }

    function launchNextAutostartEntry(): void {
        if (autostartIndex >= autostartQueue.length)
            return;
        const entry = autostartQueue[autostartIndex++];
        launchAutostartEntry(entry);
        if (autostartIndex < autostartQueue.length) {
            autostartTimer.interval = Math.max(1, Math.round(entry.delay * 1000));
            autostartTimer.restart();
        }
    }

    function runAutostart(): void {
        const entries = GlobalConfig.hyprland.autostartApps.apps.map(normaliseAutostartEntry).filter(entry => entry?.command);
        if (!GlobalConfig.hyprland.autostartApps.enabled || entries.length === 0)
            return;
        autostartQueue = entries;
        autostartIndex = 0;
        launchNextAutostartEntry();
    }

    function desiredOptions(): var {
        const config = GlobalConfig.hyprland;
        return {
            "animations:enabled": config.animations.enabled,
            "decoration:rounding": config.decoration.rounding,
            "decoration:active_opacity": config.decoration.activeOpacity,
            "decoration:inactive_opacity": config.decoration.inactiveOpacity,
            "decoration:blur:enabled": config.decoration.blur.enabled,
            "decoration:blur:size": config.decoration.blur.size,
            "decoration:blur:passes": config.decoration.blur.passes,
            "decoration:shadow:enabled": config.decoration.shadow.enabled,
            "decoration:shadow:range": config.decoration.shadow.range,
            "general:border_size": config.general.borderSize,
            "general:gaps_in": config.general.gapsIn,
            "general:gaps_out": config.general.gapsOut,
            "general:layout": config.general.layout,
            "input:kb_layout": config.input.kbLayout,
            "input:numlock_by_default": config.input.numlock,
            "input:repeat_delay": config.input.repeatDelay,
            "input:repeat_rate": config.input.repeatRate,
            "input:follow_mouse": config.input.followMouse,
            "input:touchpad:natural_scroll": config.input.touchpad.naturalScroll,
            "input:touchpad:disable_while_typing": config.input.touchpad.disableWhileTyping,
            "input:touchpad:clickfinger_behavior": config.input.touchpad.clickfingerBehavior,
            "input:touchpad:scroll_factor": config.input.touchpad.scrollFactor
        };
    }

    function requestApply(): void {
        if (enabled && !GameMode.enabled)
            applyTimer.restart();
        else
            applyTimer.stop();
    }

    function apply(): void {
        if (!enabled || GameMode.enabled || !HyprControl.providerReady)
            return;
        HyprControl.setOptions(desiredOptions());
        Hypr.extras.batchMessage(animationPresetMessages(GlobalConfig.hyprland.animations.animation));
    }

    Component.onCompleted: requestApply()
    onEnabledChanged: requestApply()

    Connections {
        function onProviderReadyChanged(): void {
            root.requestApply();
        }

        target: HyprControl
    }

    Connections {
        function onEnabledChanged(): void {
            root.requestApply();
        }

        target: GameMode
    }

    Connections {
        function onEnabledChanged(): void {
            root.requestApply();
        }

        target: GlobalConfig.hyprland
    }

    Connections {
        function onAnimationChanged(): void {
            root.requestApply();
        }
        function onEnabledChanged(): void {
            root.requestApply();
        }

        target: GlobalConfig.hyprland.animations
    }

    Connections {
        function onRoundingChanged(): void {
            root.requestApply();
        }
        function onActiveOpacityChanged(): void {
            root.requestApply();
        }
        function onInactiveOpacityChanged(): void {
            root.requestApply();
        }

        target: GlobalConfig.hyprland.decoration
    }

    Connections {
        function onEnabledChanged(): void {
            root.requestApply();
        }
        function onSizeChanged(): void {
            root.requestApply();
        }
        function onPassesChanged(): void {
            root.requestApply();
        }

        target: GlobalConfig.hyprland.decoration.blur
    }

    Connections {
        function onEnabledChanged(): void {
            root.requestApply();
        }
        function onRangeChanged(): void {
            root.requestApply();
        }

        target: GlobalConfig.hyprland.decoration.shadow
    }

    Connections {
        function onBorderSizeChanged(): void {
            root.requestApply();
        }
        function onGapsInChanged(): void {
            root.requestApply();
        }
        function onGapsOutChanged(): void {
            root.requestApply();
        }
        function onLayoutChanged(): void {
            root.requestApply();
        }

        target: GlobalConfig.hyprland.general
    }

    Connections {
        function onKbLayoutChanged(): void {
            root.requestApply();
        }
        function onNumlockChanged(): void {
            root.requestApply();
        }
        function onRepeatDelayChanged(): void {
            root.requestApply();
        }
        function onRepeatRateChanged(): void {
            root.requestApply();
        }
        function onFollowMouseChanged(): void {
            root.requestApply();
        }

        target: GlobalConfig.hyprland.input
    }

    Connections {
        function onNaturalScrollChanged(): void {
            root.requestApply();
        }
        function onDisableWhileTypingChanged(): void {
            root.requestApply();
        }
        function onClickfingerBehaviorChanged(): void {
            root.requestApply();
        }
        function onScrollFactorChanged(): void {
            root.requestApply();
        }

        target: GlobalConfig.hyprland.input.touchpad
    }

    Timer {
        id: applyTimer

        interval: 100
        onTriggered: root.apply()
    }

    Timer {
        id: startupAutostartTimer

        interval: 1500
        running: true
        onTriggered: autostartLockProcess.running = true
    }

    Timer {
        id: autostartTimer

        repeat: false
        onTriggered: root.launchNextAutostartEntry()
    }

    Process {
        id: autostartLockProcess

        command: [
            "sh",
            "-c",
            "lock=\"${XDG_RUNTIME_DIR:-/tmp}/caelestia-autostart-${UID}.lock\"; (set -o noclobber; : > \"$lock\") 2>/dev/null"
        ]
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0)
                root.runAutostart();
        }
    }
}
