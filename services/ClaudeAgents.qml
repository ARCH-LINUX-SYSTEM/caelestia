pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// Tracks running Claude Code sessions and their subagents.
// Data comes from scripts/claude-agents-watch (one JSON snapshot per line, only on change).
Singleton {
    id: root

    readonly property bool available: hasOutput && watcher.running
    readonly property var sessions: sessionList
    readonly property int activeCount: sessionList.length
    readonly property int busyCount: sessionList.filter(s => s.status === "busy").length
    readonly property int subagentCount: sessionList.reduce((n, s) => n + (s.subagents ?? []).filter(a => a.status === "running").length, 0)
    readonly property bool anyBusy: busyCount > 0
    readonly property bool needsAttention: sessionList.some(s => s.status === "waiting")

    readonly property string watcherPath: `${Quickshell.shellDir}/scripts/claude-agents-watch`
    readonly property int minRestartDelay: 1000
    readonly property int maxRestartDelay: 60000

    property var sessionList: []
    property bool hasOutput
    property bool pythonMissing
    property bool receivedSnapshot
    property int restartDelay: minRestartDelay
    property string pendingFocusId
    property var pendingFocusAncestors: []

    // Centred "flow" overlay (modules/claudeflow): which session it shows, if open.
    property bool flowOpen
    property string flowSessionId

    signal subagentFinished(var session, var subagent)
    signal attentionRequested(var session)

    function openFlow(sessionId: string): void {
        flowSessionId = sessionId || (sessionList[0]?.sessionId ?? "");
        flowOpen = true;
    }

    function closeFlow(): void {
        flowOpen = false;
    }

    function statusRank(status: string): int {
        return status === "waiting" ? 0 : status === "busy" ? 1 : 2;
    }

    function ingest(line: string): void {
        let snapshot;
        try {
            snapshot = JSON.parse(line);
        } catch (error) {
            console.warn("ClaudeAgents: unable to parse watcher output:", error);
            return;
        }
        if (!snapshot || !Array.isArray(snapshot.sessions))
            return;

        hasOutput = true;
        restartDelay = minRestartDelay;

        const next = snapshot.sessions.filter(s => s && typeof s.sessionId === "string").sort((a, b) => statusRank(a.status) - statusRank(b.status) || (b.updatedAt ?? 0) - (a.updatedAt ?? 0));

        // Update state before emitting so handlers see the new snapshot.
        const prev = sessionList;
        const isFirst = !receivedSnapshot;
        receivedSnapshot = true;
        sessionList = next;
        if (!isFirst)
            diff(prev, next);
    }

    function diff(prev: var, next: var): void {
        const prevById = {};
        for (const s of prev)
            prevById[s.sessionId] = s;

        for (const s of next) {
            const old = prevById[s.sessionId];

            if (s.status === "waiting" && old?.status !== "waiting")
                attentionRequested(s);

            if (!old)
                continue;

            const current = {};
            for (const a of s.subagents ?? [])
                current[a.id] = a;

            for (const a of old.subagents ?? []) {
                if (a.status !== "running")
                    continue;
                const now = current[a.id];
                // A "tool:<id>" placeholder disappearing means it was renamed to the real agent id.
                if (!now && String(a.id).startsWith("tool:"))
                    continue;
                // Finished explicitly, or dropped from a still-alive session.
                if (!now || now.status !== "running")
                    subagentFinished(s, now ?? Object.assign({}, a, {
                        status: "done",
                        endedAt: Date.now()
                    }));
            }
        }
    }

    function scheduleRestart(): void {
        hasOutput = false;
        if (pythonMissing)
            return;
        restartTimer.interval = restartDelay;
        restartTimer.restart();
        restartDelay = Math.min(restartDelay * 2, maxRestartDelay);
    }

    function focusSession(sessionId: string): void {
        const session = sessionList.find(s => s.sessionId === sessionId);
        const pid = Number(session?.pid ?? 0);
        if (!session || !Number.isInteger(pid) || pid <= 1)
            return;

        pendingFocusId = sessionId;
        pendingFocusAncestors = [];
        ancestorProc.exec(["sh", "-c", "p=$1; while [ -n \"$p\" ] && [ \"$p\" -gt 1 ]; do echo \"$p\"; p=$(sed -n 's/^PPid:[[:space:]]*//p' \"/proc/$p/status\" 2>/dev/null); done", "sh", String(pid)]);
    }

    // Returns the address (without 0x) of the window owned by the nearest ancestor, or "".
    function matchWindow(clients: var, ancestors: var): string {
        let best = "";
        let bestRank = ancestors.length;
        for (const client of clients) {
            const rank = ancestors.indexOf(Number(client?.pid ?? -1));
            if (rank >= 0 && rank < bestRank) {
                bestRank = rank;
                const address = String(client.address ?? "");
                best = address.startsWith("0x") ? address.slice(2) : address;
            }
        }
        return best;
    }

    function luaEscape(value: string): string {
        return value.replace(/\\/g, "\\\\").replace(/\"/g, "\\\"");
    }

    function focusAddress(address: string): void {
        const selector = `address:0x${address}`;
        Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({ window = "${luaEscape(selector)}" })` : `focuswindow ${selector}`);
    }

    function resolveFocus(): void {
        const ancestors = pendingFocusAncestors;
        if (ancestors.length === 0)
            return;

        const toplevels = Hypr.toplevels.values.map(t => ({
                    pid: t.lastIpcObject?.pid,
                    address: t.address
                }));
        const address = matchWindow(toplevels, ancestors);
        if (address) {
            focusAddress(address);
            pendingFocusId = "";
            return;
        }

        // Toplevel IPC data may be stale or incomplete; ask hyprctl directly.
        clientsProc.exec(["hyprctl", "clients", "-j"]);
    }

    Component.onCompleted: pythonCheck.running = true

    Process {
        id: pythonCheck

        command: ["sh", "-c", "command -v python3"]
        onExited: code => { // qmllint disable signal-handler-parameters
            root.pythonMissing = code !== 0;
            if (root.pythonMissing)
                console.warn("ClaudeAgents: python3 not found; Claude session tracking disabled");
            else
                watcher.running = true;
        }
    }

    Process {
        id: watcher

        command: ["python3", root.watcherPath]
        stdout: SplitParser {
            onRead: data => root.ingest(data)
        }
        onRunningChanged: {
            if (!running)
                root.scheduleRestart();
        }
    }

    Timer {
        id: restartTimer

        onTriggered: {
            if (!root.pythonMissing && !watcher.running)
                watcher.running = true;
        }
    }

    Process {
        id: ancestorProc

        stdout: StdioCollector {
            onStreamFinished: {
                root.pendingFocusAncestors = text.split("\n").map(l => Number(l.trim())).filter(n => Number.isInteger(n) && n > 1);
                root.resolveFocus();
            }
        }
    }

    Process {
        id: clientsProc

        stdout: StdioCollector {
            onStreamFinished: {
                let clients = [];
                try {
                    clients = JSON.parse(text);
                } catch (error) {
                    console.warn("ClaudeAgents: unable to parse hyprctl clients:", error);
                }
                const address = Array.isArray(clients) ? root.matchWindow(clients, root.pendingFocusAncestors) : "";
                if (address)
                    root.focusAddress(address);
                else if (root.pendingFocusId)
                    console.info("ClaudeAgents: no window found for session", root.pendingFocusId);
                root.pendingFocusId = "";
            }
        }
    }
}
