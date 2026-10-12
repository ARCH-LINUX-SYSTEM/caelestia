pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services

ColumnLayout {
    id: root

    required property PopoutState popouts

    // Ticks once a second while this popout is loaded (the Popout loader in
    // Content.qml unloads it when inactive, so the timer never runs hidden)
    property real now: Date.now()

    readonly property var sessionIds: (ClaudeAgents.sessions ?? []).map(s => s.sessionId)

    function sessionById(id: string): var {
        return (ClaudeAgents.sessions ?? []).find(s => s.sessionId === id) ?? null;
    }

    function formatDuration(ms: real): string {
        if (!(ms >= 0))
            return "—";
        const total = Math.floor(ms / 1000);
        const h = Math.floor(total / 3600);
        const m = Math.floor(total / 60) % 60;
        const s = total % 60;
        if (h > 0)
            return `${h}h ${m}m`;
        if (m > 0)
            return `${m}m ${s}s`;
        return `${s}s`;
    }

    function elapsedSince(start: real, end: real): string {
        if (!start)
            return "—";
        return formatDuration((end || now) - start);
    }

    function sessionTitle(session: var): string {
        if (session?.name)
            return session.name;
        const cwd = (session?.cwd ?? "").replace(/\/+$/, "");
        return cwd.slice(cwd.lastIndexOf("/") + 1) || qsTr("Phiên Claude");
    }

    spacing: Tokens.spacing.small
    width: Tokens.sizes.bar.networkWidth

    Timer {
        running: root.visible
        repeat: true
        triggeredOnStart: true
        interval: 1000
        onTriggered: root.now = Date.now()
    }

    // Header
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.padding.small
        Layout.rightMargin: Tokens.padding.extraSmall
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: "smart_toy"
            color: Colours.palette.m3primary
            fill: 1
        }

        StyledText {
            Layout.fillWidth: true
            text: qsTr("Claude Code")
            font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
        }

        StyledText {
            visible: ClaudeAgents.activeCount > 0
            text: ClaudeAgents.subagentCount > 0 ? qsTr("%1 phiên · %2 subagent").arg(ClaudeAgents.activeCount).arg(ClaudeAgents.subagentCount) : qsTr("%1 phiên").arg(ClaudeAgents.activeCount)
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.small
        }
    }

    // Empty / unavailable state
    ColumnLayout {
        visible: root.sessionIds.length === 0
        Layout.fillWidth: true
        Layout.topMargin: Tokens.padding.large
        Layout.bottomMargin: Tokens.padding.large
        spacing: Tokens.spacing.small

        MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            text: ClaudeAgents.available ? "bedtime" : "sync_problem"
            color: Colours.palette.m3outline
            fontStyle: Tokens.font.icon.large
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: ClaudeAgents.available ? qsTr("Không có phiên Claude nào đang chạy") : qsTr("Trình theo dõi phiên chưa chạy")
            color: Colours.palette.m3onSurfaceVariant
        }
    }

    StyledFlickable {
        id: flick

        visible: root.sessionIds.length > 0
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(list.implicitHeight, 520)

        contentWidth: width
        contentHeight: list.implicitHeight
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ColumnLayout {
            id: list

            width: flick.width
            spacing: Tokens.spacing.small

            Repeater {
                // Model on ids (strings compare by value) so delegates survive watcher snapshots
                model: ScriptModel {
                    values: root.sessionIds
                }

                SessionCard {}
            }
        }
    }

    component SessionCard: StyledRect {
        id: card

        required property string modelData
        readonly property var session: root.sessionById(modelData)
        readonly property string status: session?.status ?? "idle"
        readonly property var subagents: {
            const subs = [...(session?.subagents ?? [])];
            return subs.sort((a, b) => {
                const ar = a.status === "running" ? 0 : 1;
                const br = b.status === "running" ? 0 : 1;
                if (ar !== br)
                    return ar - br;
                if (ar === 0)
                    return (b.startedAt ?? 0) - (a.startedAt ?? 0);
                return (b.endedAt ?? 0) - (a.endedAt ?? 0);
            });
        }
        readonly property int runningCount: subagents.filter(a => a.status === "running").length
        readonly property int doneCount: subagents.length - runningCount
        readonly property int maxDone: 3
        property bool showAllDone

        readonly property var visibleSubagentIds: subagents.slice(0, showAllDone ? subagents.length : runningCount + maxDone).map(a => a.id)

        Layout.fillWidth: true
        implicitHeight: cardLayout.implicitHeight + Tokens.padding.medium * 2

        radius: Tokens.rounding.large
        color: status === "waiting" ? Colours.palette.m3tertiaryContainer : Colours.tPalette.m3surfaceContainer

        opacity: 0
        scale: 0.9
        Component.onCompleted: {
            opacity = 1;
            scale = 1;
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on scale {
            Anim {}
        }

        StateLayer {
            radius: card.radius
            color: card.status === "waiting" ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurface
            onClicked: {
                ClaudeAgents.openFlow(card.modelData);
                root.popouts.hasCurrent = false;
            }
        }

        ColumnLayout {
            id: cardLayout

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Tokens.padding.medium

            spacing: Tokens.spacing.extraSmall

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                StyledText {
                    Layout.fillWidth: true
                    text: root.sessionTitle(card.session)
                    elide: Text.ElideRight
                    font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
                    color: card.status === "waiting" ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurface
                }

                StatusChip {
                    status: card.status
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: {
                    const parts = [root.elapsedSince(card.session?.startedAt ?? 0, 0)];
                    if (card.session?.currentTool)
                        parts.push(card.session.currentTool);
                    else if (card.session?.name && card.session?.cwd)
                        parts.push(card.session.cwd.replace(/\/+$/, "").split("/").pop());
                    return parts.join(" · ");
                }
                elide: Text.ElideRight
                font: Tokens.font.body.small
                color: card.status === "waiting" ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurfaceVariant
            }

            StyledText {
                visible: card.status === "waiting" && !!card.session?.lastMessage
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.extraSmall
                text: card.session?.lastMessage ?? ""
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
                font: Tokens.font.body.small
                color: Colours.palette.m3onTertiaryContainer
            }

            // Subagents
            ColumnLayout {
                visible: card.subagents.length > 0
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.small
                spacing: Tokens.spacing.extraSmall

                Repeater {
                    model: ScriptModel {
                        values: card.visibleSubagentIds
                    }

                    SubagentRow {
                        session: card.session
                    }
                }

                StyledText {
                    id: moreToggle

                    visible: card.doneCount > card.maxDone
                    Layout.leftMargin: Tokens.padding.small
                    text: card.showAllDone ? qsTr("Thu gọn") : qsTr("+%1 subagent đã xong").arg(card.doneCount - card.maxDone)
                    font: Tokens.font.label.medium
                    color: Colours.palette.m3primary

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -Tokens.padding.extraSmall
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.showAllDone = !card.showAllDone
                    }
                }
            }
        }
    }

    component SubagentRow: RowLayout {
        id: row

        required property string modelData
        required property var session
        readonly property var agent: (session?.subagents ?? []).find(a => a.id === modelData) ?? null
        readonly property bool running: agent?.status === "running"

        Layout.fillWidth: true
        Layout.leftMargin: Tokens.padding.small
        spacing: Tokens.spacing.small

        Item {
            implicitWidth: doneIcon.implicitWidth
            implicitHeight: doneIcon.implicitHeight

            CircularIndicator {
                anchors.centerIn: parent
                implicitSize: doneIcon.implicitHeight * 0.85
                strokeWidth: Math.max(2, Tokens.padding.extraSmall / 2)
                running: row.running
                visible: row.running
            }

            MaterialIcon {
                id: doneIcon

                anchors.centerIn: parent
                visible: !row.running
                text: "check_circle"
                color: Colours.palette.m3primary
                fill: 1
            }
        }

        StyledText {
            text: row.agent?.type ?? "agent"
            font: Tokens.font.label.medium
            color: Colours.palette.m3onSurface
        }

        StyledText {
            Layout.fillWidth: true
            text: {
                const desc = row.agent?.description ?? "";
                const tool = row.running ? (row.agent?.currentTool ?? "") : "";
                return tool ? (desc ? `${tool} · ${desc}` : tool) : desc;
            }
            elide: Text.ElideRight
            font: Tokens.font.body.small
            color: Colours.palette.m3onSurfaceVariant
        }

        StyledText {
            text: root.elapsedSince(row.agent?.startedAt ?? 0, row.running ? 0 : (row.agent?.endedAt ?? 0))
            font: Tokens.font.label.small
            color: Colours.palette.m3outline
        }
    }

    component StatusChip: StyledRect {
        id: chip

        required property string status
        readonly property color fg: {
            if (status === "busy")
                return Colours.palette.m3onPrimary;
            if (status === "waiting")
                return Colours.palette.m3onTertiary;
            return Colours.palette.m3onSurfaceVariant;
        }

        implicitWidth: chipRow.implicitWidth + Tokens.padding.small * 2
        implicitHeight: chipRow.implicitHeight + Tokens.padding.extraSmall

        radius: Tokens.rounding.full
        color: {
            if (status === "busy")
                return Colours.palette.m3primary;
            if (status === "waiting")
                return Colours.palette.m3tertiary;
            return Colours.tPalette.m3surfaceContainerHighest;
        }

        Behavior on implicitWidth {
            Anim {}
        }

        Row {
            id: chipRow

            anchors.centerIn: parent
            spacing: Tokens.spacing.extraSmall

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: chip.status === "busy" ? "progress_activity" : chip.status === "waiting" ? "front_hand" : "pause_circle"
                color: chip.fg
                fill: 1
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                animate: true
                text: chip.status === "busy" ? qsTr("Đang chạy") : chip.status === "waiting" ? qsTr("Chờ bạn") : qsTr("Rảnh")
                font: Tokens.font.label.medium
                color: chip.fg
            }
        }
    }
}
