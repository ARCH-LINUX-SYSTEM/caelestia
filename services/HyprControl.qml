pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services

Singleton {
    id: root

    readonly property var optionSpecs: ({
            "animations:enabled": {
                type: "bool"
            },
            "decoration:blur:enabled": {
                type: "bool"
            },
            "decoration:shadow:enabled": {
                type: "bool"
            },
            "general:gaps_in": {
                type: "intVector",
                minimum: 0,
                maximum: 100
            },
            "general:gaps_out": {
                type: "intVector",
                minimum: 0,
                maximum: 100
            },
            "general:border_size": {
                type: "int",
                minimum: 0,
                maximum: 20
            },
            "decoration:rounding": {
                type: "int",
                minimum: 0,
                maximum: 100
            },
            "decoration:active_opacity": {
                type: "real",
                minimum: 0.1,
                maximum: 1
            },
            "decoration:inactive_opacity": {
                type: "real",
                minimum: 0.1,
                maximum: 1
            },
            "decoration:blur:size": {
                type: "int",
                minimum: 1,
                maximum: 20
            },
            "decoration:blur:passes": {
                type: "int",
                minimum: 1,
                maximum: 6
            },
            "decoration:shadow:range": {
                type: "int",
                minimum: 0,
                maximum: 100
            },
            "general:layout": {
                type: "string",
                values: ["dwindle", "master", "scrolling"]
            },
            "input:kb_layout": {
                type: "string",
                pattern: /^[A-Za-z0-9_+,-]+$/
            },
            "input:numlock_by_default": {
                type: "bool"
            },
            "input:repeat_delay": {
                type: "int",
                minimum: 100,
                maximum: 1000
            },
            "input:repeat_rate": {
                type: "int",
                minimum: 10,
                maximum: 100
            },
            "input:follow_mouse": {
                type: "int",
                minimum: 0,
                maximum: 3
            },
            "input:touchpad:natural_scroll": {
                type: "bool"
            },
            "input:touchpad:disable_while_typing": {
                type: "bool"
            },
            "input:touchpad:clickfinger_behavior": {
                type: "bool"
            },
            "input:touchpad:scroll_factor": {
                type: "real",
                minimum: 0.1,
                maximum: 3
            },
            "general:allow_tearing": {
                type: "bool"
            }
        })
    readonly property list<string> gameModeKeys: ["animations:enabled", "decoration:shadow:enabled", "decoration:blur:enabled", "general:gaps_in", "general:gaps_out", "general:border_size", "decoration:rounding", "general:allow_tearing"]
    readonly property var gameModeOverrides: ({
            "animations:enabled": false,
            "decoration:shadow:enabled": false,
            "decoration:blur:enabled": false,
            "general:gaps_in": 0,
            "general:gaps_out": 0,
            "general:border_size": 1,
            "decoration:rounding": 0,
            "general:allow_tearing": true
        })

    readonly property var monitors: Hypr.monitors.values
    readonly property int monitorCount: monitors.length
    readonly property int workspaceCount: Hypr.workspaces.values.length
    readonly property int windowCount: Hypr.toplevels.values.length
    readonly property string focusedMonitorName: Hypr.focusedMonitor?.name ?? ""
    readonly property string activeWorkspaceName: Hypr.focusedWorkspace?.name ?? ""

    // Monitor data is requested only after Quickshell's provider probe completes.
    // Requiring it here prevents Standard commands from racing an unresolved Lua provider.
    readonly property bool optionsReady: Object.keys(Hypr.options).length > 0
    readonly property bool providerReady: optionsReady && Hypr.providerReady
    readonly property string providerName: providerReady ? (Hypr.usingLua ? "Lua" : "Standard") : qsTr("Đang phát hiện")

    readonly property bool supportsAnimations: supportsOption("animations:enabled")
    readonly property bool supportsBlur: supportsOption("decoration:blur:enabled")
    readonly property bool supportsShadow: supportsOption("decoration:shadow:enabled")
    readonly property bool supportsGapsIn: supportsOption("general:gaps_in")
    readonly property bool supportsGapsOut: supportsOption("general:gaps_out")
    readonly property bool supportsBorderSize: supportsOption("general:border_size")
    readonly property bool supportsRounding: supportsOption("decoration:rounding")

    readonly property bool animationsEnabled: _optionBool("animations:enabled", true)
    readonly property bool blurEnabled: _optionBool("decoration:blur:enabled", false)
    readonly property bool shadowEnabled: _optionBool("decoration:shadow:enabled", false)
    readonly property int gapsIn: _optionVectorFirst("general:gaps_in", 0)
    readonly property int gapsOut: _optionVectorFirst("general:gaps_out", 0)
    readonly property int borderSize: _optionInt("general:border_size", 0)
    readonly property int rounding: _optionInt("decoration:rounding", 0)

    property var pendingOptions: ({})
    property var inFlightOptions: ({})
    property int applyAttempts

    signal optionsApplied(options: var)
    signal optionsApplyFailed(options: var, reason: string)

    function supportsOption(key: string): bool {
        return Object.keys(Hypr.options).includes(key);
    }

    function _normaliseIntVector(value: var, spec: var, clampToRange: bool): var {
        if (typeof value === "number") {
            if (isNaN(value) || !isFinite(value) || value !== Math.round(value))
                return undefined;
            const normalisedValue = clampToRange ? Math.max(spec.minimum, Math.min(spec.maximum, value)) : value;
            return normalisedValue.toString();
        }

        if (typeof value !== "string")
            return undefined;

        const trimmedValue = value.trim();
        if (!trimmedValue)
            return undefined;
        const rawParts = trimmedValue.split(/\s+/);
        if (rawParts.length > 4)
            return undefined;

        const normalisedParts = [];
        for (const part of rawParts) {
            if (!/^[+-]?\d+$/.test(part))
                return undefined;

            const numericPart = Number(part);
            if (isNaN(numericPart) || !isFinite(numericPart))
                return undefined;
            normalisedParts.push(clampToRange ? Math.max(spec.minimum, Math.min(spec.maximum, numericPart)) : numericPart);
        }
        return normalisedParts.join(" ");
    }

    function _normaliseOption(key: string, value: var, clampToRange: bool): var {
        const spec = optionSpecs[key];
        if (!spec)
            return undefined;

        if (spec.type === "bool") {
            if (value === true || value === 1 || value === "1" || value === "true")
                return true;
            if (value === false || value === 0 || value === "0" || value === "false")
                return false;

            const numericBool = Number(value);
            return isNaN(numericBool) || !isFinite(numericBool) ? undefined : numericBool !== 0;
        }

        if (spec.type === "intVector")
            return _normaliseIntVector(value, spec, clampToRange);

        if (spec.type === "string") {
            if (typeof value !== "string")
                return undefined;
            const stringValue = value.trim();
            if (!stringValue || (spec.values && !spec.values.includes(stringValue)) || (spec.pattern && !spec.pattern.test(stringValue)))
                return undefined;
            return stringValue;
        }

        const numericValue = Number(value);
        if (isNaN(numericValue) || !isFinite(numericValue))
            return undefined;

        if (spec.type === "real") {
            if (!clampToRange)
                return numericValue;
            return Math.max(spec.minimum, Math.min(spec.maximum, numericValue));
        }

        const roundedValue = Math.round(numericValue);
        if (!clampToRange)
            return roundedValue;
        return Math.max(spec.minimum, Math.min(spec.maximum, roundedValue));
    }

    function _currentOption(key: string): var {
        if (!supportsOption(key))
            return undefined;
        return _normaliseOption(key, Hypr.options[key], false);
    }

    function _optionBool(key: string, fallback: bool): bool {
        const value = _currentOption(key);
        return value === undefined ? fallback : value;
    }

    function _optionInt(key: string, fallback: int): int {
        const value = _currentOption(key);
        return value === undefined ? fallback : value;
    }

    function _optionVectorFirst(key: string, fallback: int): int {
        const value = _currentOption(key);
        if (value === undefined)
            return fallback;
        return Number(value.split(" ")[0]);
    }

    function _queueOption(key: string, value: var, clampToRange: bool): bool {
        if (!providerReady || !supportsOption(key))
            return false;

        const normalised = _normaliseOption(key, value, clampToRange);
        if (normalised === undefined)
            return false;

        const next = Object.assign({}, pendingOptions);
        next[key] = normalised;
        pendingOptions = next;
        applyTimer.restart();
        return true;
    }

    function optionsMatch(options: var): bool {
        if (!options || typeof options !== "object" || Array.isArray(options))
            return false;

        for (const [key, value] of Object.entries(options)) {
            const expected = _normaliseOption(key, value, false);
            const current = _currentOption(key);
            if (expected === undefined || current === undefined || (typeof expected === "number" && typeof current === "number" ? Math.abs(current - expected) > 0.000001 : current !== expected))
                return false;
        }
        return true;
    }

    function optionsContainExpected(options: var, expected: var): bool {
        if (!options || typeof options !== "object" || Array.isArray(options) || !expected || typeof expected !== "object" || Array.isArray(expected))
            return false;

        let compared = false;
        for (const [key, value] of Object.entries(expected)) {
            if (!supportsOption(key))
                continue;

            compared = true;
            if (!(key in options) || _normaliseOption(key, options[key], false) !== _normaliseOption(key, value, false))
                return false;
        }
        return compared;
    }

    function gameModeOverridesActive(): bool {
        const supportedOverrides = {};
        for (const key of gameModeKeys) {
            if (supportsOption(key))
                supportedOverrides[key] = gameModeOverrides[key];
        }
        return Object.keys(supportedOverrides).length > 0 && optionsMatch(supportedOverrides);
    }

    function _acknowledgeInFlight(): bool {
        if (Object.keys(inFlightOptions).length === 0 || !optionsMatch(inFlightOptions))
            return false;

        const applied = Object.assign({}, inFlightOptions);
        confirmationTimer.stop();
        inFlightOptions = {};
        applyAttempts = 0;
        optionsApplied(applied);

        if (Object.keys(pendingOptions).length > 0)
            applyTimer.restart();
        return true;
    }

    function _deferInFlight(): void {
        if (Object.keys(inFlightOptions).length === 0)
            return;

        confirmationTimer.stop();
        pendingOptions = Object.assign({}, inFlightOptions, pendingOptions);
        inFlightOptions = {};
        applyAttempts = 0;
    }

    function _failInFlight(reason: string): void {
        if (Object.keys(inFlightOptions).length === 0)
            return;

        const failed = Object.assign({}, inFlightOptions);
        const hasNewerPending = Object.keys(pendingOptions).length > 0;
        confirmationTimer.stop();
        // Values queued while this batch was in flight are newer and must win.
        pendingOptions = Object.assign({}, failed, pendingOptions);
        inFlightOptions = {};
        applyAttempts = 0;
        optionsApplyFailed(failed, reason);

        if (hasNewerPending)
            applyTimer.restart();
    }

    function _sendInFlight(): void {
        if (!providerReady) {
            _deferInFlight();
            return;
        }
        if (Object.keys(inFlightOptions).length === 0 || _acknowledgeInFlight())
            return;

        applyAttempts++;
        Hypr.extras.applyOptions(Object.assign({}, inFlightOptions));
        confirmationTimer.restart();
    }

    function flushOptions(): void {
        if (!providerReady || Object.keys(pendingOptions).length === 0 || Object.keys(inFlightOptions).length > 0)
            return;

        const options = Object.assign({}, pendingOptions);
        pendingOptions = {};
        if (optionsMatch(options)) {
            optionsApplied(options);
            if (Object.keys(pendingOptions).length > 0)
                applyTimer.restart();
            return;
        }

        inFlightOptions = options;
        applyAttempts = 0;
        _sendInFlight();
    }

    function setAnimationsEnabled(enabled: bool): void {
        _queueOption("animations:enabled", enabled, true);
    }

    function setBlurEnabled(enabled: bool): void {
        _queueOption("decoration:blur:enabled", enabled, true);
    }

    function setShadowEnabled(enabled: bool): void {
        _queueOption("decoration:shadow:enabled", enabled, true);
    }

    function setGapsIn(value: int): void {
        _queueOption("general:gaps_in", value, true);
    }

    function setGapsOut(value: int): void {
        _queueOption("general:gaps_out", value, true);
    }

    function setBorderSize(value: int): void {
        _queueOption("general:border_size", value, true);
    }

    function setRounding(value: int): void {
        _queueOption("decoration:rounding", value, true);
    }

    function setOption(key: string, value: var): bool {
        return _queueOption(key, value, true);
    }

    function setOptions(options: var): bool {
        if (!options || typeof options !== "object" || Array.isArray(options))
            return false;

        let queued = false;
        for (const [key, value] of Object.entries(options))
            queued = _queueOption(key, value, true) || queued;
        return queued;
    }

    function snapshotGameModeOptions(): var {
        const snapshot = {};
        for (const key of gameModeKeys) {
            const value = _currentOption(key);
            if (value !== undefined)
                snapshot[key] = value;
        }
        return snapshot;
    }

    function applyGameModeOverrides(): bool {
        let queued = false;
        for (const key of gameModeKeys)
            queued = _queueOption(key, gameModeOverrides[key], true) || queued;
        return queued;
    }

    function restoreGameModeOptions(snapshot: var): bool {
        if (!snapshot || typeof snapshot !== "object" || Array.isArray(snapshot))
            return false;

        let queued = false;
        for (const key of gameModeKeys) {
            if (key in snapshot)
                queued = _queueOption(key, snapshot[key], false) || queued;
        }
        return queued;
    }

    function refresh(): void {
        Hypr.extras.refreshOptions();
        Hypr.extras.refreshDevices();
        Hyprland.refreshMonitors();
        Hyprland.refreshWorkspaces();
        Hyprland.refreshToplevels();
    }

    function reload(): void {
        if (providerReady)
            Hypr.extras.message("reload");
    }

    onProviderReadyChanged: {
        if (!providerReady) {
            root._deferInFlight();
        } else if (Object.keys(pendingOptions).length > 0) {
            applyTimer.restart();
        }
    }

    Connections {
        function onOptionsChanged(): void {
            root._acknowledgeInFlight();
        }

        target: Hypr.extras
    }

    Timer {
        id: applyTimer

        interval: 0
        onTriggered: root.flushOptions()
    }

    Timer {
        id: confirmationTimer

        interval: 1200
        onTriggered: {
            if (root._acknowledgeInFlight())
                return;
            if (!root.providerReady) {
                root._deferInFlight();
            } else if (root.applyAttempts < 3) {
                root._sendInFlight();
            } else {
                root._failInFlight(qsTr("Hyprland không xác nhận thay đổi sau 3 lần thử"));
            }
        }
    }
}
