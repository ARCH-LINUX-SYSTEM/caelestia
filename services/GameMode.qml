pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import qs.services

Singleton {
    id: root

    property alias enabled: props.enabled
    property string pendingOperation
    property bool notifyOperation
    property bool operationFailureReported

    function _beginOperation(operation: string, notifyCompletion: bool): void {
        if (pendingOperation !== operation) {
            operationFailureReported = false;
            notifyOperation = notifyCompletion;
        } else {
            notifyOperation = notifyOperation || notifyCompletion;
        }
        pendingOperation = operation;
    }

    function _snapshot(): var {
        if (!props.snapshotJson)
            return undefined;

        try {
            const snapshot = JSON.parse(props.snapshotJson);
            return snapshot && typeof snapshot === "object" && !Array.isArray(snapshot) ? snapshot : undefined;
        } catch (error) {
            console.warn("GameMode: unable to parse Hyprland snapshot:", error);
            return undefined;
        }
    }

    function _reportOperationFailure(reason: string): void {
        if (operationFailureReported)
            return;

        operationFailureReported = true;
        if (notifyOperation && GlobalConfig.utilities.toasts.gameModeChanged)
            Toaster.toast(qsTr("Không thể cập nhật chế độ trò chơi"), reason, "warning");
    }

    function _finishPendingOperation(): void {
        if (pendingOperation === "apply") {
            if (!props.enabled || !HyprControl.gameModeOverridesActive())
                return;

            const shouldNotify = notifyOperation;
            pendingOperation = "";
            notifyOperation = false;
            operationFailureReported = false;
            if (shouldNotify && GlobalConfig.utilities.toasts.gameModeChanged)
                Toaster.toast(qsTr("Đã bật chế độ trò chơi"), qsTr("Đã tắt hiệu ứng động, làm mờ, khoảng cách và bóng đổ của Hyprland"), "gamepad");
            return;
        }

        if (pendingOperation !== "restore" || props.enabled)
            return;

        const snapshot = _snapshot();
        if (!snapshot || !HyprControl.optionsMatch(snapshot))
            return;

        const shouldNotify = notifyOperation;
        props.snapshotJson = "";
        pendingOperation = "";
        notifyOperation = false;
        operationFailureReported = false;
        if (shouldNotify && GlobalConfig.utilities.toasts.gameModeChanged)
            Toaster.toast(qsTr("Đã tắt chế độ trò chơi"), qsTr("Đã khôi phục cài đặt Hyprland"), "gamepad");
    }

    function applyOverrides(notifyCompletion = false): bool {
        _beginOperation("apply", notifyCompletion);
        if (!HyprControl.providerReady)
            return false;

        if (!props.snapshotJson) {
            const snapshot = HyprControl.snapshotGameModeOptions();
            if (Object.keys(snapshot).length === 0)
                return false;
            props.snapshotJson = JSON.stringify(snapshot);
        }

        return HyprControl.applyGameModeOverrides();
    }

    function restoreSnapshot(notifyCompletion = false): bool {
        _beginOperation("restore", notifyCompletion);
        if (!props.snapshotJson) {
            pendingOperation = "";
            notifyOperation = false;
            return true;
        }
        if (!HyprControl.providerReady)
            return false;

        const snapshot = _snapshot();
        if (!snapshot) {
            _reportOperationFailure(qsTr("Ảnh chụp cấu hình Hyprland không hợp lệ; dữ liệu vẫn được giữ lại"));
            return false;
        }

        return HyprControl.restoreGameModeOptions(snapshot);
    }

    function setDynamicConfs(): void {
        applyOverrides();
    }

    onEnabledChanged: {
        if (enabled) {
            const queued = applyOverrides(true);
            if (GlobalConfig.utilities.toasts.gameModeChanged)
                Toaster.toast(qsTr("Đang bật chế độ trò chơi"), queued ? qsTr("Đang chờ Hyprland xác nhận thay đổi") : qsTr("Đang chờ Hyprland sẵn sàng để áp dụng"), "gamepad");
        } else {
            const queued = restoreSnapshot(true);
            if (pendingOperation && !operationFailureReported && GlobalConfig.utilities.toasts.gameModeChanged)
                Toaster.toast(qsTr("Đang tắt chế độ trò chơi"), queued ? qsTr("Đang chờ Hyprland xác nhận cấu hình đã khôi phục") : qsTr("Sẽ khôi phục khi Hyprland sẵn sàng"), "gamepad");
        }
    }

    PersistentProperties {
        id: props

        property bool enabled: false
        property string snapshotJson

        reloadableId: "gameMode"
    }

    Connections {
        function onConfigReloaded(): void {
            if (props.enabled)
                reapplyTimer.restart();
        }

        target: Hypr
    }

    Connections {
        function onOptionsApplied(): void {
            root._finishPendingOperation();
        }

        function onOptionsApplyFailed(options: var, reason: string): void {
            if (!root.pendingOperation)
                return;

            const expected = root.pendingOperation === "apply" ? HyprControl.gameModeOverrides : root._snapshot();
            if (HyprControl.optionsContainExpected(options, expected))
                root._reportOperationFailure(reason);
        }

        function onProviderReadyChanged(): void {
            if (!HyprControl.providerReady)
                return;

            if (props.enabled)
                root.applyOverrides(false);
            else if (props.snapshotJson)
                root.restoreSnapshot(false);
        }

        target: HyprControl
    }

    Timer {
        id: reapplyTimer

        interval: 150
        onTriggered: {
            if (props.enabled)
                root.applyOverrides(false);
        }
    }

    IpcHandler {
        function isEnabled(): bool {
            return props.enabled;
        }

        function toggle(): void {
            props.enabled = !props.enabled;
        }

        function enable(): void {
            props.enabled = true;
        }

        function disable(): void {
            props.enabled = false;
        }

        target: "gameMode"
    }
}
