pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.modules.launcher.items
import qs.modules.launcher.services

StyledListView {
    id: root

    required property SearchBar search
    required property ScreenState screenState

    property string displayText
    property bool nonAppReady

    readonly property string requestedState: stateForText(search.text)
    readonly property string displayState: stateForText(displayText)

    function appPrefix(): string {
        return GlobalConfig.launcher.appPrefix || GlobalConfig.search.prefix.app;
    }

    function stripPrefix(text: string, prefix: string): string {
        return prefix && text.startsWith(prefix) ? text.slice(prefix.length).trimStart() : text;
    }

    function appSearchText(text: string): string {
        return stripPrefix(text, appPrefix());
    }

    function mathExpressionForText(text: string): string {
        const actionPrefix = `${GlobalConfig.launcher.actionPrefix}calc `;
        if (text.startsWith(actionPrefix))
            return text.slice(actionPrefix.length);
        return stripPrefix(text, GlobalConfig.search.prefix.math).trim();
    }

    function shellCommandForText(text: string): string {
        return stripPrefix(text, GlobalConfig.search.prefix.shellCommand).replace(/^file:\/\//, "").trim();
    }

    function webQueryForText(text: string): string {
        return stripPrefix(text, GlobalConfig.search.prefix.webSearch).trim();
    }

    function webUrl(query: string): string {
        let expanded = query;
        for (const site of GlobalConfig.search.excludedSites)
            expanded += ` -site:${site}`;
        return GlobalConfig.search.engineBaseUrl + encodeURIComponent(expanded);
    }

    function commandAction(text: string): var {
        const command = shellCommandForText(text);
        return {
            name: command || qsTr("Nhập lệnh shell"),
            desc: qsTr("Chạy bằng /bin/sh sau khi bạn chọn kết quả"),
            icon: "terminal",
            onClicked: list => {
                if (!command)
                    return;
                list.screenState.launcher = false;
                Quickshell.execDetached(["sh", "-c", command]);
            }
        };
    }

    function webAction(text: string): var {
        const query = webQueryForText(text);
        return {
            name: query ? qsTr("Tìm trên web: %1").arg(query) : qsTr("Nhập nội dung tìm kiếm"),
            desc: GlobalConfig.search.engineBaseUrl,
            icon: "travel_explore",
            onClicked: list => {
                if (!query)
                    return;
                list.screenState.launcher = false;
                Qt.openUrlExternally(root.webUrl(query));
            }
        };
    }

    function searchActionsForText(text: string, defaults = false): var {
        const shellPrefix = GlobalConfig.search.prefix.shellCommand;
        const webPrefix = GlobalConfig.search.prefix.webSearch;
        if (shellPrefix && text.startsWith(shellPrefix))
            return [commandAction(text)];
        if (webPrefix && text.startsWith(webPrefix))
            return [webAction(text)];
        return defaults && text.trim() ? [webAction(text), commandAction(text)] : [];
    }

    function mixedResultsForText(text: string): var {
        const actions = searchActionsForText(text, true);
        const appLimit = Math.max(0, Config.launcher.maxShown - actions.length);
        const apps = Apps.search(appSearchText(text)).slice(0, appLimit).map(item => ({
            kind: "app",
            value: item
        }));
        return [...apps, ...actions.map(item => ({
            kind: "action",
            value: item
        }))];
    }

    function scheduleNonAppResults(): void {
        nonAppTimer.stop();
        nonAppReady = false;
        if (!GlobalConfig.search.prefix.showDefaultActionsWithoutPrefix || !search.text.trim())
            return;
        if (GlobalConfig.search.nonAppResultDelay <= 0)
            nonAppReady = true;
        else
            nonAppTimer.restart();
    }

    function syncDisplayText(): void {
        if (screenState.launcher && requestedState === displayState)
            displayText = search.text;
    }

    function stateForText(text: string): string {
        const actionPrefix = GlobalConfig.launcher.actionPrefix;
        if (actionPrefix && text.startsWith(actionPrefix)) {
            for (const action of ["calc", "scheme", "variant"])
                if (text.startsWith(`${actionPrefix}${action} `))
                    return action;

            return "actions";
        }

        const mathPrefix = GlobalConfig.search.prefix.math;
        if ((mathPrefix && text.startsWith(mathPrefix)) || /^\s*\d/.test(text))
            return "calc";

        const shellPrefix = GlobalConfig.search.prefix.shellCommand;
        const webPrefix = GlobalConfig.search.prefix.webSearch;
        if ((shellPrefix && text.startsWith(shellPrefix)) || (webPrefix && text.startsWith(webPrefix)))
            return "searchActions";

        if (GlobalConfig.search.prefix.showDefaultActionsWithoutPrefix && nonAppReady && text.trim())
            return "mixed";

        return "apps";
    }

    function resultsForText(text: string): var {
        switch (stateForText(text)) {
        case "actions":
            return Actions.query(text);
        case "mixed":
            return mixedResultsForText(text);
        case "searchActions":
            return searchActionsForText(text);
        case "calc":
            return [0];
        case "scheme":
            return Schemes.query(text);
        case "variant":
            return M3Variants.query(text);
        default:
            return Apps.search(appSearchText(text));
        }
    }

    model: ScriptModel {
        values: root.resultsForText(root.displayText)
        onValuesChanged: root.currentIndex = 0
    }

    spacing: Tokens.spacing.small
    orientation: Qt.Vertical
    implicitHeight: (Tokens.sizes.launcher.itemHeight + spacing) * Math.min(Config.launcher.maxShown, count) - spacing

    preferredHighlightBegin: 0
    preferredHighlightEnd: height
    highlightRangeMode: ListView.ApplyRange

    highlightFollowsCurrentItem: false
    highlight: StyledRect {
        radius: Tokens.rounding.large
        color: Colours.palette.m3onSurface
        opacity: 0.08

        y: root.currentItem?.y ?? 0
        implicitWidth: root.width
        implicitHeight: root.currentItem?.implicitHeight ?? 0

        Behavior on y {
            Anim {}
        }
    }

    state: screenState.launcher ? requestedState : displayState

    onStateChanged: {
        if (state === "scheme" || state === "variant")
            Schemes.reload();
    }

    Component.onCompleted: {
        displayText = search.text;
        scheduleNonAppResults();
    }

    states: [
        State {
            name: "apps"

            PropertyChanges {
                root.delegate: appItem
            }
        },
        State {
            name: "actions"

            PropertyChanges {
                root.delegate: actionItem
            }
        },
        State {
            name: "mixed"

            PropertyChanges {
                root.delegate: mixedItem
            }
        },
        State {
            name: "searchActions"

            PropertyChanges {
                root.delegate: actionItem
            }
        },
        State {
            name: "calc"

            PropertyChanges {
                root.delegate: calcItem
            }
        },
        State {
            name: "scheme"

            PropertyChanges {
                root.delegate: schemeItem
            }
        },
        State {
            name: "variant"

            PropertyChanges {
                root.delegate: variantItem
            }
        }
    ]

    transitions: Transition {
        SequentialAnimation {
            ParallelAnimation {
                Anim {
                    target: root
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: Tokens.anim.durations.small
                    easing: Tokens.anim.standardAccel
                }
                Anim {
                    target: root
                    property: "scale"
                    from: 1
                    to: 0.9
                    duration: Tokens.anim.durations.small
                    easing: Tokens.anim.standardAccel
                }
            }
            PropertyAction {
                target: root
                property: "delegate"
                value: null
            }
            ScriptAction {
                script: root.displayText = root.search.text
            }
            PropertyAction {
                target: root
                property: "delegate"
            }
            ParallelAnimation {
                Anim {
                    target: root
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Tokens.anim.durations.small
                    easing: Tokens.anim.standardDecel
                }
                Anim {
                    target: root
                    property: "scale"
                    from: 0.9
                    to: 1
                    duration: Tokens.anim.durations.small
                    easing: Tokens.anim.standardDecel
                }
            }
            PropertyAction {
                targets: [root.add, root.remove]
                property: "enabled"
                value: true
            }
        }
    }

    StyledScrollBar.vertical: StyledScrollBar {
        flickable: root
    }

    add: Transition {
        enabled: !root.state

        Anim {
            type: Anim.DefaultEffects
            property: "opacity"
            from: 0
            to: 1
        }
    }

    remove: Transition {
        enabled: !root.state

        Anim {
            type: Anim.DefaultEffects
            property: "opacity"
            from: 1
            to: 0
        }
    }

    move: Transition {
        Anim {
            property: "y"
        }
        Anim {
            type: Anim.DefaultEffects
            property: "opacity"
            to: 1
        }
    }

    addDisplaced: Transition {
        Anim {
            property: "y"
            type: Anim.StandardSmall
        }
        Anim {
            type: Anim.DefaultEffects
            property: "opacity"
            to: 1
        }
    }

    displaced: Transition {
        Anim {
            property: "y"
        }
        Anim {
            type: Anim.DefaultEffects
            property: "opacity"
            to: 1
        }
    }

    Component {
        id: appItem

        AppItem {
            screenState: root.screenState
        }
    }

    Component {
        id: actionItem

        ActionItem {
            list: root
        }
    }

    Component {
        id: mixedItem

        Loader {
            id: mixedLoader

            required property var modelData

            function onClicked(): void {
                item?.onClicked();
            }

            anchors.left: parent?.left
            anchors.right: parent?.right
            height: item?.implicitHeight ?? Tokens.sizes.launcher.itemHeight
            sourceComponent: modelData.kind === "app" ? mixedAppItem : mixedActionItem

            Component {
                id: mixedAppItem

                AppItem {
                    modelData: mixedLoader.modelData.value
                    screenState: root.screenState
                }
            }

            Component {
                id: mixedActionItem

                ActionItem {
                    modelData: mixedLoader.modelData.value
                    list: root
                }
            }
        }
    }

    Component {
        id: calcItem

        CalcItem {
            list: root
        }
    }

    Component {
        id: schemeItem

        SchemeItem {
            list: root
        }
    }

    Component {
        id: variantItem

        VariantItem {
            list: root
        }
    }

    Connections {
        function onTextChanged() {
            root.scheduleNonAppResults();
            root.syncDisplayText();
        }

        target: root.search
    }

    Connections {
        function onLauncherChanged() {
            root.syncDisplayText();
        }

        target: root.screenState
    }

    Connections {
        function onNonAppResultDelayChanged(): void {
            root.scheduleNonAppResults();
        }

        target: GlobalConfig.search
    }

    Connections {
        function onShowDefaultActionsWithoutPrefixChanged(): void {
            root.scheduleNonAppResults();
        }

        target: GlobalConfig.search.prefix
    }

    Timer {
        id: nonAppTimer

        interval: GlobalConfig.search.nonAppResultDelay
        onTriggered: root.nonAppReady = true
    }
}
