pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import qs.services

// Global (single-instance) glue for the Claude Code sessions tracker:
// toasts for ClaudeAgents signals and the `claudeAgents` IPC target that
// opens the bar popout on the focused monitor.
Scope {
    id: root

    readonly property string popoutName: "claudeagents"
    property var pendingFinished: []
    property var lastAttention: ({})

    function sessionTitle(session: var): string {
        if (session?.name)
            return session.name;
        const cwd = (session?.cwd ?? "").replace(/\/+$/, "");
        return cwd.slice(cwd.lastIndexOf("/") + 1) || qsTr("Phiên Claude");
    }

    function activePopouts(): var {
        return ShellState.componentsForActive()?.panels?.popouts ?? null;
    }

    function isOpen(): bool {
        const popouts = activePopouts();
        return !!popouts && popouts.hasCurrent && popouts.currentName === popoutName;
    }

    function openPopout(): void {
        const comps = ShellState.componentsForActive();
        const popouts = comps?.panels?.popouts;
        if (!popouts)
            return;

        // Anchor next to the bar indicator when it is shown, otherwise centre on the bar
        const icon = comps.find("taskbarClaudeAgents");
        const bar = comps.bar;
        if (icon && bar)
            popouts.currentCenter = icon.mapToItem(bar, 0, icon.height / 2).y;
        else
            popouts.currentCenter = (bar?.height ?? comps.modelData.height) / 2;

        popouts.currentName = popoutName;
        popouts.hasCurrent = true;
    }

    function closePopout(): void {
        const popouts = activePopouts();
        if (popouts && popouts.currentName === popoutName)
            popouts.hasCurrent = false;
    }

    function flushFinished(): void {
        const items = pendingFinished;
        pendingFinished = [];
        if (items.length === 0)
            return;

        if (items.length === 1) {
            const it = items[0];
            const what = it.subagent?.description ? `${it.subagent?.type ?? "agent"}: ${it.subagent.description}` : (it.subagent?.type ?? "agent");
            Toaster.toast(qsTr("Subagent đã xong"), `${what} — ${sessionTitle(it.session)}`, "task_alt", Toast.Info, 4000);
        } else {
            const names = [...new Set(items.map(it => sessionTitle(it.session)))].join(", ");
            Toaster.toast(qsTr("%1 subagent đã xong").arg(items.length), names, "task_alt", Toast.Info, 4000);
        }
    }

    Connections {
        function onSubagentFinished(session: var, subagent: var): void {
            // Coalesce bursts (parallel subagents often finish together) into one toast
            root.pendingFinished = [...root.pendingFinished,
                {
                    session,
                    subagent
                }
            ];
            coalesce.restart();
        }

        function onAttentionRequested(session: var): void {
            const id = session?.sessionId ?? "";
            const now = Date.now();
            // At most one attention toast per session per 30s
            if (now - (root.lastAttention[id] ?? 0) < 30000)
                return;
            root.lastAttention[id] = now;

            // Notification fires for idle reminders too ("Claude is waiting for your input");
            // only permission-type prompts get a prominent toast, idle reminders a short, low-key one
            const msg = session?.lastMessage ?? qsTr("Claude đang chờ bạn");
            const important = /permission|approv|allow|quyền/i.test(msg);
            const title = root.sessionTitle(session);
            if (important)
                Toaster.toast(qsTr("Claude cần bạn cho phép — %1").arg(title), msg, "front_hand", Toast.Warning, 8000);
            else
                Toaster.toast(qsTr("Claude đang chờ — %1").arg(title), msg, "hourglass_empty", Toast.Info, 3000);
        }

        target: ClaudeAgents
    }

    Timer {
        id: coalesce

        interval: 1500
        onTriggered: root.flushFinished()
    }

    IpcHandler {
        function toggle(): void {
            if (root.isOpen())
                root.closePopout();
            else
                root.openPopout();
        }

        function open(): void {
            root.openPopout();
        }

        function close(): void {
            root.closePopout();
        }

        // Centred flow overlay (modules/claudeflow) for the given session, or the first one
        function flow(sessionId: string): void {
            if (ClaudeAgents.flowOpen && (!sessionId || sessionId === ClaudeAgents.flowSessionId))
                ClaudeAgents.closeFlow();
            else
                ClaudeAgents.openFlow(sessionId);
        }

        target: "claudeAgents"
    }
}
