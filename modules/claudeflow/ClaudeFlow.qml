pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services

// Centred overlay showing the "flow" of one Claude Code session: the main agent
// on the left, connectors to each subagent on the right, and a timeline of the
// recent tool calls ("steps") of every agent. Opened from the bar popout
// (ClaudeAgents.openFlow) or IPC `claudeAgents flow`.
Scope {
    id: root

    property bool overlayVisible
    property bool presented
    property string targetScreen: ""
    property real now: Date.now()

    readonly property var sessions: ClaudeAgents.sessions ?? []
    readonly property var session: sessions.find(s => s.sessionId === ClaudeAgents.flowSessionId) ?? null
    readonly property var subagents: [...(session?.subagents ?? [])].sort((a, b) => (a.startedAt ?? 0) - (b.startedAt ?? 0))
    readonly property var subagentIds: subagents.map(a => a.id)
    readonly property int runningCount: subagents.filter(a => a.status === "running").length

    function screenForActiveMonitor(): string {
        const monitor = Hypr.focusedMonitor;
        const screen = Screens.screens.find(s => Hypr.monitorFor(s) === monitor);
        return screen?.name ?? Screens.screens[0]?.name ?? "";
    }

    function sessionTitle(s: var): string {
        if (s?.name)
            return s.name;
        const cwd = (s?.cwd ?? "").replace(/\/+$/, "");
        return cwd.slice(cwd.lastIndexOf("/") + 1) || qsTr("Phiên Claude");
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

    function elapsed(start: real, end: real): string {
        return start ? formatDuration((end || now) - start) : "—";
    }

    function toolIcon(tool: string): string {
        switch (tool) {
        case "Bash":
            return "terminal";
        case "Read":
            return "description";
        case "Edit":
        case "MultiEdit":
        case "Write":
        case "NotebookEdit":
            return "edit_document";
        case "Grep":
        case "Glob":
            return "search";
        case "Agent":
        case "Task":
            return "account_tree";
        case "WebFetch":
        case "WebSearch":
            return "travel_explore";
        case "Prompt":
            return "chat";
        default:
            return "build";
        }
    }

    function css(c: color, alpha: real): string {
        return `rgba(${Math.round(c.r * 255)},${Math.round(c.g * 255)},${Math.round(c.b * 255)},${alpha})`;
    }

    function stepSession(delta: int): void {
        if (sessions.length < 2)
            return;
        const i = Math.max(0, sessions.findIndex(s => s.sessionId === ClaudeAgents.flowSessionId));
        ClaudeAgents.flowSessionId = sessions[(i + delta + sessions.length) % sessions.length].sessionId;
    }

    Connections {
        function onFlowOpenChanged(): void {
            if (ClaudeAgents.flowOpen) {
                hideTimer.stop();
                root.targetScreen = root.screenForActiveMonitor();
                root.now = Date.now();
                root.overlayVisible = true;
                root.presented = true;
            } else {
                root.presented = false;
                hideTimer.restart();
            }
        }

        target: ClaudeAgents
    }

    Timer {
        id: hideTimer

        interval: 260
        onTriggered: root.overlayVisible = false
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.overlayVisible
        onTriggered: root.now = Date.now()
    }

    Variants {
        model: Screens.screens

        StyledWindow {
            id: win

            required property ShellScreen modelData

            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            WlrLayershell.layer: WlrLayer.Overlay
            anchors.bottom: true
            anchors.left: true
            anchors.right: true
            anchors.top: true
            name: "claude-flow"
            screen: modelData
            visible: root.overlayVisible && root.targetScreen === modelData.name

            onVisibleChanged: {
                if (visible)
                    keys.forceActiveFocus();
            }

            Item {
                id: keys

                anchors.fill: parent
                focus: win.visible

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape)
                        ClaudeAgents.closeFlow();
                    else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab)
                        root.stepSession(1);
                    else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab)
                        root.stepSession(-1);
                    else
                        return;
                    event.accepted = true;
                }

                // Dimmed backdrop; clicking outside the panel closes it
                Rectangle {
                    anchors.fill: parent
                    color: Colours.palette.m3scrim
                    opacity: root.presented ? 0.45 : 0

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: ClaudeAgents.closeFlow()
                    }
                }

                StyledRect {
                    id: panel

                    anchors.centerIn: parent
                    width: Math.min(parent.width - 96, 1280)
                    height: Math.min(parent.height - 96, 800)
                    radius: Tokens.rounding.extraLarge
                    color: Colours.palette.m3surface
                    border.color: Colours.palette.m3outlineVariant
                    border.width: 1
                    clip: true

                    opacity: root.presented ? 1 : 0
                    scale: root.presented ? 1 : 0.94

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                    Behavior on scale {
                        Anim {
                            type: Anim.DefaultSpatial
                        }
                    }

                    // Swallow clicks so they don't reach the backdrop
                    MouseArea {
                        anchors.fill: parent
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.extraLarge
                        spacing: Tokens.spacing.large

                        Header {}

                        // Empty state: session ended while the overlay was open
                        ColumnLayout {
                            visible: !root.session
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: Tokens.spacing.small

                            Item {
                                Layout.fillHeight: true
                            }
                            MaterialIcon {
                                Layout.alignment: Qt.AlignHCenter
                                text: "bedtime"
                                color: Colours.palette.m3outline
                                fontStyle: Tokens.font.icon.large
                            }
                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: qsTr("Phiên này đã kết thúc")
                                color: Colours.palette.m3onSurfaceVariant
                            }
                            Item {
                                Layout.fillHeight: true
                            }
                        }

                        FlowBody {
                            visible: !!root.session
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }
                    }
                }
            }
        }
    }

    component Header: RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.medium

        StyledRect {
            implicitWidth: implicitHeight
            implicitHeight: headIcon.implicitHeight + Tokens.padding.medium * 2
            radius: Tokens.rounding.full
            color: Colours.palette.m3primaryContainer

            MaterialIcon {
                id: headIcon

                anchors.centerIn: parent
                text: "account_tree"
                color: Colours.palette.m3onPrimaryContainer
                fill: 1
                fontStyle: Tokens.font.icon.medium
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                text: qsTr("Luồng agent · %1").arg(root.sessionTitle(root.session))
                font: Tokens.font.title.small
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            StyledText {
                text: {
                    const parts = [];
                    if (root.session?.cwd)
                        parts.push(root.session.cwd);
                    parts.push(qsTr("%1 subagent đang chạy · %2 đã xong").arg(root.runningCount).arg(root.subagents.length - root.runningCount));
                    return parts.join("  ·  ");
                }
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
                elide: Text.ElideMiddle
                Layout.fillWidth: true
            }
        }

        // Session switcher (only when more than one session)
        Row {
            visible: root.sessions.length > 1
            spacing: Tokens.spacing.extraSmall

            Repeater {
                model: ScriptModel {
                    values: root.sessions.map(s => s.sessionId)
                }

                StyledRect {
                    id: tab

                    required property string modelData
                    readonly property bool selected: modelData === ClaudeAgents.flowSessionId
                    readonly property var tabSession: root.sessions.find(s => s.sessionId === modelData) ?? null

                    implicitWidth: tabText.implicitWidth + Tokens.padding.medium * 2
                    implicitHeight: tabText.implicitHeight + Tokens.padding.small * 2
                    radius: Tokens.rounding.full
                    color: selected ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainerHigh

                    Behavior on color {
                        CAnim {}
                    }

                    StateLayer {
                        radius: tab.radius
                        color: Colours.palette.m3onSurface
                        onClicked: ClaudeAgents.flowSessionId = tab.modelData
                    }

                    StyledText {
                        id: tabText

                        anchors.centerIn: parent
                        text: {
                            const t = root.sessionTitle(tab.tabSession);
                            return t.length > 18 ? t.slice(0, 17) + "…" : t;
                        }
                        font: Tokens.font.label.medium
                        color: tab.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                    }
                }
            }
        }

        IconTextButton {
            visible: !!root.session
            icon: "terminal"
            text: qsTr("Mở terminal")
            type: IconTextButton.Tonal
            isRound: true
            onClicked: {
                ClaudeAgents.focusSession(ClaudeAgents.flowSessionId);
                ClaudeAgents.closeFlow();
            }
        }

        IconButton {
            icon: "close"
            type: IconButton.Text
            onClicked: ClaudeAgents.closeFlow()
        }
    }

    component FlowBody: Item {
        id: body

        readonly property real gap: 96

        // Main agent node
        StyledRect {
            id: mainNode

            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Math.min(360, body.width * 0.34)
            radius: Tokens.rounding.large
            color: Colours.palette.m3surfaceContainer
            border.color: root.session?.status === "busy" ? Colours.palette.m3primary : root.session?.status === "waiting" ? Colours.palette.m3tertiary : "transparent"
            border.width: 2

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.small

                RowLayout {
                    id: mainHead

                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        text: "smart_toy"
                        color: Colours.palette.m3primary
                        fill: 1
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Agent chính")
                        font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
                    }
                    StatusChip {
                        status: root.session?.status ?? "idle"
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: {
                        const parts = [root.elapsed(root.session?.startedAt ?? 0, 0)];
                        if (root.session?.currentTool)
                            parts.push(qsTr("đang chạy %1").arg(root.session.currentTool));
                        return parts.join(" · ");
                    }
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }

                StyledRect {
                    visible: root.session?.status === "waiting" && !!root.session?.lastMessage
                    Layout.fillWidth: true
                    implicitHeight: waitText.implicitHeight + Tokens.padding.small * 2
                    radius: Tokens.rounding.small
                    color: Colours.palette.m3tertiaryContainer

                    StyledText {
                        id: waitText

                        anchors.fill: parent
                        anchors.margins: Tokens.padding.small
                        text: root.session?.lastMessage ?? ""
                        wrapMode: Text.Wrap
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onTertiaryContainer
                    }
                }

                StyledText {
                    Layout.topMargin: Tokens.spacing.small
                    text: qsTr("Các bước gần đây")
                    font: Tokens.font.label.medium
                    color: Colours.palette.m3outline
                }

                StepList {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    steps: root.session?.steps ?? []
                    scrollable: true
                }
            }
        }

        // Connectors main → subagents. Running links get a moving dash.
        Canvas {
            id: links

            property real dashOffset

            function settle(): void {
                animTick.settleFrames = 20;
                requestPaint();
            }

            anchors.fill: parent
            z: -1

            onWidthChanged: settle()
            onHeightChanged: settle()
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const origin = mainNode.mapToItem(links, mainNode.width, mainHead.y + Tokens.padding.large + mainHead.height / 2);
                for (let i = 0; i < cards.count; i++) {
                    const card = cards.itemAt(i);
                    if (!card)
                        continue;
                    const end = card.mapToItem(links, 0, Math.min(card.height / 2, 34));
                    if (end.y < -40 || end.y > height + 40)
                        continue;
                    const running = card.running;
                    const midX = (origin.x + end.x) / 2;
                    ctx.beginPath();
                    ctx.moveTo(origin.x, origin.y);
                    ctx.bezierCurveTo(midX, origin.y, midX, end.y, end.x, end.y);
                    ctx.lineWidth = running ? 2.5 : 1.5;
                    ctx.strokeStyle = running ? root.css(Colours.palette.m3primary, 0.9) : root.css(Colours.palette.m3outlineVariant, 0.9);
                    ctx.setLineDash(running ? [8, 6] : []);
                    ctx.lineDashOffset = running ? -dashOffset : 0;
                    ctx.stroke();

                    ctx.setLineDash([]);
                    ctx.beginPath();
                    ctx.arc(end.x, end.y, 4, 0, 2 * Math.PI);
                    ctx.fillStyle = running ? root.css(Colours.palette.m3primary, 1) : root.css(Colours.palette.m3outline, 1);
                    ctx.fill();
                }
                if (cards.count > 0) {
                    ctx.beginPath();
                    ctx.arc(origin.x, origin.y, 5, 0, 2 * Math.PI);
                    ctx.fillStyle = root.css(Colours.palette.m3primary, 1);
                    ctx.fill();
                }
            }

            // ~25fps while something is moving (running links, scroll, entry animations)
            Timer {
                id: animTick

                property int settleFrames: 20

                interval: 40
                repeat: true
                running: root.overlayVisible && (root.runningCount > 0 || settleFrames > 0)
                onTriggered: {
                    if (settleFrames > 0)
                        settleFrames--;
                    links.dashOffset = (links.dashOffset + 1.2) % 1000;
                    links.requestPaint();
                }
            }

            Connections {
                function onContentYChanged(): void {
                    links.requestPaint();
                }

                target: subFlick
            }
            Connections {
                function onSubagentIdsChanged(): void {
                    links.settle();
                }
                function onPresentedChanged(): void {
                    links.settle();
                }

                target: root
            }
        }

        // Subagent nodes
        StyledFlickable {
            id: subFlick

            anchors.left: mainNode.right
            anchors.leftMargin: body.gap
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            contentWidth: width
            contentHeight: grid.implicitHeight
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            GridLayout {
                id: grid

                width: subFlick.width
                columns: 1
                columnSpacing: Tokens.spacing.medium
                rowSpacing: Tokens.spacing.medium

                Repeater {
                    id: cards

                    model: ScriptModel {
                        values: root.subagentIds
                    }

                    SubagentCard {}
                }
            }
        }

        ColumnLayout {
            visible: root.subagents.length === 0
            anchors.centerIn: subFlick
            spacing: Tokens.spacing.small

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "hub"
                color: Colours.palette.m3outline
                fontStyle: Tokens.font.icon.large
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Chưa có subagent nào — agent chính đang tự làm")
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }

    component SubagentCard: StyledRect {
        id: card

        required property string modelData
        readonly property var agent: root.subagents.find(a => a.id === modelData) ?? null
        readonly property bool running: agent?.status === "running"

        Layout.fillWidth: true
        Layout.alignment: Qt.AlignTop
        implicitHeight: cardCol.implicitHeight + Tokens.padding.large * 2
        radius: Tokens.rounding.large
        color: running ? Colours.palette.m3surfaceContainerHigh : Colours.palette.m3surfaceContainer
        border.color: running ? Colours.palette.m3primary : Colours.palette.m3outlineVariant
        border.width: running ? 2 : 1

        opacity: 0
        scale: 0.92
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
        Behavior on border.color {
            CAnim {}
        }

        ColumnLayout {
            id: cardCol

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.small

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                Item {
                    implicitWidth: doneIcon.implicitWidth
                    implicitHeight: doneIcon.implicitHeight

                    CircularIndicator {
                        anchors.centerIn: parent
                        implicitSize: doneIcon.implicitHeight * 0.85
                        strokeWidth: Math.max(2, Tokens.padding.extraSmall / 2)
                        running: card.running
                        visible: card.running
                    }
                    MaterialIcon {
                        id: doneIcon

                        anchors.centerIn: parent
                        visible: !card.running
                        text: "check_circle"
                        color: Colours.palette.m3primary
                        fill: 1
                    }
                }

                StyledText {
                    text: card.agent?.type ?? "agent"
                    font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    text: root.elapsed(card.agent?.startedAt ?? 0, card.running ? 0 : (card.agent?.endedAt ?? 0))
                    font: Tokens.font.label.medium
                    color: Colours.palette.m3outline
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: text.length > 0
                text: card.agent?.description ?? ""
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }

            StepChain {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.extraSmall
                steps: (card.agent?.steps ?? []).slice(-8)
                emptyText: card.running ? qsTr("Đang khởi động…") : qsTr("Không có dữ liệu bước")
            }
        }
    }

    // Horizontal pipeline of a subagent's tool calls: Read → Edit → Bash …
    component StepChain: Flow {
        id: chain

        property var steps: []
        property string emptyText

        spacing: Tokens.spacing.extraSmall

        StyledText {
            visible: chain.steps.length === 0
            text: chain.emptyText
            font: Tokens.font.body.small
            color: Colours.palette.m3outline
        }

        Repeater {
            model: chain.steps

            Row {
                id: link

                required property var modelData
                required property int index
                readonly property bool running: modelData?.status === "running"
                readonly property bool failed: modelData?.status === "error"

                spacing: Tokens.spacing.extraSmall

                MaterialIcon {
                    visible: link.index > 0
                    anchors.verticalCenter: parent.verticalCenter
                    text: "chevron_right"
                    color: Colours.palette.m3outline
                }

                StyledRect {
                    implicitWidth: pillRow.implicitWidth + Tokens.padding.small * 2
                    implicitHeight: pillRow.implicitHeight + Tokens.padding.extraSmall * 2
                    radius: Tokens.rounding.full
                    color: link.failed ? Colours.palette.m3errorContainer : link.running ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHighest

                    SequentialAnimation on opacity {
                        running: link.running
                        loops: Animation.Infinite
                        alwaysRunToEnd: true

                        NumberAnimation {
                            to: 0.55
                            duration: 700
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            to: 1
                            duration: 700
                            easing.type: Easing.InOutQuad
                        }
                    }

                    Row {
                        id: pillRow

                        readonly property color fg: link.failed ? Colours.palette.m3onErrorContainer : link.running ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant

                        anchors.centerIn: parent
                        spacing: Tokens.spacing.extraSmall

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: link.failed ? "error" : root.toolIcon(link.modelData?.tool ?? "")
                            color: pillRow.fg
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: {
                                const tool = link.modelData?.tool ?? "";
                                const sum = link.modelData?.summary ?? "";
                                // Only the newest step (or a running one) carries its summary, to keep the chain short
                                const showSum = sum && (link.running || link.index === chain.steps.length - 1);
                                return showSum ? `${tool} · ${sum.length > 40 ? sum.slice(0, 39) + "…" : sum}` : tool;
                            }
                            font: Tokens.font.label.medium
                            color: pillRow.fg
                        }
                    }
                }
            }
        }
    }

    // Vertical timeline of tool calls, oldest first.
    component StepList: Item {
        id: stepList

        property var steps: []
        property bool scrollable
        property string emptyText: qsTr("Chưa có bước nào")

        implicitHeight: scrollable ? 0 : Math.max(stepCol.implicitHeight, 20)

        StyledText {
            visible: stepList.steps.length === 0
            text: stepList.emptyText
            font: Tokens.font.body.small
            color: Colours.palette.m3outline
        }

        StyledFlickable {
            id: stepFlick

            anchors.fill: parent
            contentWidth: width
            contentHeight: stepCol.implicitHeight
            interactive: stepList.scrollable && contentHeight > height
            boundsBehavior: Flickable.StopAtBounds
            clip: stepList.scrollable

            // Follow the newest step
            onContentHeightChanged: {
                if (stepList.scrollable)
                    contentY = Math.max(0, contentHeight - height);
            }

            Column {
                id: stepCol

                width: stepFlick.width
                spacing: 0

                Repeater {
                    model: stepList.steps

                    StepRow {
                        last: index === stepList.steps.length - 1
                    }
                }
            }
        }
    }

    component StepRow: Item {
        id: step

        required property var modelData
        required property int index
        property bool last
        readonly property bool running: modelData?.status === "running"
        readonly property bool failed: modelData?.status === "error"

        width: parent?.width ?? 0
        implicitHeight: stepRow.implicitHeight + Tokens.spacing.small
        height: implicitHeight

        // Timeline rail
        Rectangle {
            visible: !step.last
            x: dot.x + dot.width / 2 - width / 2
            y: dot.y + dot.height
            width: 2
            height: step.height - dot.height
            color: Colours.palette.m3outlineVariant
        }

        RowLayout {
            id: stepRow

            width: parent.width
            spacing: Tokens.spacing.small

            StyledRect {
                id: dot

                Layout.alignment: Qt.AlignTop
                implicitWidth: toolIcon.implicitHeight + Tokens.padding.extraSmall * 2
                implicitHeight: implicitWidth
                radius: Tokens.rounding.full
                color: step.failed ? Colours.palette.m3errorContainer : step.running ? Colours.palette.m3primary : Colours.tPalette.m3surfaceContainerHighest

                MaterialIcon {
                    id: toolIcon

                    anchors.centerIn: parent
                    text: step.failed ? "error" : root.toolIcon(step.modelData?.tool ?? "")
                    color: step.failed ? Colours.palette.m3onErrorContainer : step.running ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                }

                SequentialAnimation on opacity {
                    running: step.running
                    loops: Animation.Infinite
                    alwaysRunToEnd: true

                    NumberAnimation {
                        to: 0.45
                        duration: 600
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        to: 1
                        duration: 600
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                text: step.modelData?.tool ?? ""
                font: Tokens.font.label.medium
                color: step.running ? Colours.palette.m3primary : Colours.palette.m3onSurface
            }

            StyledText {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                text: step.modelData?.summary ?? ""
                elide: Text.ElideRight
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                text: step.running ? root.elapsed(step.modelData?.at ?? 0, 0) : root.formatDuration(root.now - (step.modelData?.endedAt || step.modelData?.at || root.now))
                font: Tokens.font.label.small
                color: Colours.palette.m3outline
            }
        }
    }

    component StatusChip: StyledRect {
        id: chip

        required property string status
        readonly property color fg: status === "busy" ? Colours.palette.m3onPrimary : status === "waiting" ? Colours.palette.m3onTertiary : Colours.palette.m3onSurfaceVariant

        implicitWidth: chipRow.implicitWidth + Tokens.padding.small * 2
        implicitHeight: chipRow.implicitHeight + Tokens.padding.extraSmall
        radius: Tokens.rounding.full
        color: status === "busy" ? Colours.palette.m3primary : status === "waiting" ? Colours.palette.m3tertiary : Colours.tPalette.m3surfaceContainerHighest

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
                text: chip.status === "busy" ? qsTr("Đang chạy") : chip.status === "waiting" ? qsTr("Chờ bạn") : qsTr("Rảnh")
                font: Tokens.font.label.medium
                color: chip.fg
            }
        }
    }
}
