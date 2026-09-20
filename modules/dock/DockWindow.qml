pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.effects
import qs.components.widgets
import qs.services
import qs.modules.nexus

StyledWindow {
    id: root

    readonly property ScreenState screenState: ShellState.forScreen(root.screen)
    readonly property HyprlandMonitor monitor: Hypr.monitorFor(root.screen)
    readonly property bool hasFullscreen: root.monitor?.activeWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false
    readonly property real cellSize: Math.max(28, GlobalConfig.dock.height - Tokens.padding.small * 2)
    readonly property real outerPadding: Tokens.padding.small
    readonly property bool revealed: !root.hasFullscreen && (root.pinned || (GlobalConfig.dock.hoverToReveal && root.hovered))
    readonly property var dockItems: root.computeDockItems()

    // Sentinel pinnedApps entry for Caelestia's own Settings (Nexus): it has no
    // DesktopEntry/.desktop file to launch via Apps.launch, so it's special-cased in
    // computeDockItems() instead of going through the usual DesktopEntries.byId lookup.
    readonly property string nexusPinId: "@caelestia-nexus"

    // macOS-style launch bounce: key -> launch timestamp (ms). A key is pruned once its
    // window maps (see onDockItemsChanged) or after launchTimeoutMs, whichever comes first.
    readonly property int launchTimeoutMs: 8000
    readonly property bool anyLaunching: Object.keys(root.launching).length > 0
    // Extra headroom above the icon row so the bounce isn't clipped by the layer-shell surface.
    readonly property real bounceHeadroom: root.anyLaunching ? root.cellSize * 0.5 : 0

    property bool pinned: GlobalConfig.dock.pinnedOnStartup
    property bool hovered: false
    property var launching: ({})

    function startLaunching(key: string): void {
        const next = Object.assign({}, root.launching);
        next[key] = Date.now();
        root.launching = next;
    }

    function stopLaunching(key: string): void {
        if (!(key in root.launching))
            return;
        const next = Object.assign({}, root.launching);
        delete next[key];
        root.launching = next;
    }

    function pruneStaleLaunches(): void {
        const now = Date.now();
        let changed = false;
        const next = Object.assign({}, root.launching);
        for (const key in next) {
            if (now - next[key] > root.launchTimeoutMs) {
                delete next[key];
                changed = true;
            }
        }
        if (changed)
            root.launching = next;
    }

    function ignoredMatch(cls: string): bool {
        for (const pattern of GlobalConfig.dock.ignoredAppRegexes) {
            try {
                if (new RegExp(pattern).test(cls))
                    return true;
            } catch (e) {
                // Invalid patterns are already surfaced by the config validator.
            }
        }
        return false;
    }

    function computeDockItems(): var {
        const groups = new Map();
        for (const toplevel of Hypr.toplevels.values) {
            const ipc = toplevel.lastIpcObject ?? {};
            if (ipc.mapped !== true || ipc.hidden === true || ipc.noFocus === true)
                continue;

            const cls = String(ipc.class ?? "").trim();
            if (!cls || root.ignoredMatch(cls))
                continue;

            const entry = DesktopEntries.heuristicLookup(cls);
            const key = entry?.id ?? cls;
            if (!groups.has(key))
                groups.set(key, {
                    addresses: [],
                    entry: entry ?? null,
                    name: entry?.name ?? toplevel.title ?? cls
                });
            groups.get(key).addresses.push(String(toplevel.address ?? ""));
        }

        const items = [];
        const used = new Set();

        for (const id of GlobalConfig.dock.pinnedApps) {
            if (id === root.nexusPinId) {
                items.push({
                    key: `pinned:${id}`,
                    id,
                    entry: null,
                    name: qsTr("Cài đặt"),
                    addresses: [],
                    pinned: true,
                    iconGlyph: "settings",
                    activateOverride: () => WindowFactory.create(root.screen)
                });
                continue;
            }

            const entry = DesktopEntries.byId(id);
            const key = entry?.id ?? id;
            const group = groups.get(key);
            if (group)
                used.add(key);

            items.push({
                key: `pinned:${id}`,
                id,
                entry: entry ?? null,
                name: entry?.name ?? id,
                addresses: group?.addresses ?? [],
                pinned: true
            });
        }

        for (const [key, group] of groups) {
            if (used.has(key))
                continue;

            items.push({
                key: `running:${key}`,
                id: group.entry?.id ?? key,
                entry: group.entry,
                name: group.name,
                addresses: group.addresses,
                pinned: false
            });
        }

        return items;
    }

    name: "dock"
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    anchors.bottom: true
    implicitWidth: pill.implicitWidth + root.outerPadding * 2
    implicitHeight: (root.revealed ? pill.implicitHeight + root.outerPadding * 2 : Math.max(1, GlobalConfig.dock.hoverRegionHeight)) + root.bounceHeadroom

    onDockItemsChanged: {
        for (const item of root.dockItems) {
            if (item.addresses.length > 0)
                root.stopLaunching(item.key);
        }
    }

    Behavior on implicitHeight {
        Anim {
            type: Anim.EmphasizedLarge
        }
    }

    HoverHandler {
        onHoveredChanged: root.hovered = hovered
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.anyLaunching
        onTriggered: root.pruneStaleLaunches()
    }

    Item {
        id: clipWrap

        anchors.fill: parent
        clip: true

        StyledRect {
            id: bg

            visible: GlobalConfig.dock.showBackground
            anchors.left: pill.left
            anchors.right: pill.right
            anchors.top: pill.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: -root.outerPadding
            anchors.rightMargin: -root.outerPadding
            anchors.topMargin: -root.outerPadding
            radius: Tokens.rounding.extraLarge
            color: Colours.tPalette.m3surfaceContainer
            border.width: 1
            border.color: Colours.palette.m3outlineVariant

            Elevation {
                anchors.fill: parent
                radius: parent.radius
                level: 2

                z: -1
            }
        }

        Row {
            id: pill

            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.outerPadding
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Tokens.spacing.small
            opacity: root.revealed ? 1 : 0

            Behavior on opacity {
                Anim {
                    type: Anim.FastEffects
                }
            }

            HoverHandler {
                id: rowHover
            }

            Repeater {
                // A count (not the root.dockItems array itself) as the model: dockItems is a
                // brand new array every time it recomputes (any toplevel opening/closing
                // anywhere, or a pin toggle, re-runs computeDockItems()), and QML can't diff
                // one JS array against another for identity. Repeater treats that as "the
                // model changed" and destroys+recreates every delegate, which was dropping
                // hover state and glitching the pin button mid-click. Indexing into the array
                // instead lets existing delegates be reused and just get new property values.
                model: root.dockItems.length

                DockIcon {
                    required property int index

                    modelData: root.dockItems[index]
                    cellSize: root.cellSize
                    rowHoverX: rowHover.hovered ? rowHover.point.position.x : -100000
                    monochrome: GlobalConfig.dock.monochromeIcons
                    showPinButton: GlobalConfig.dock.showPinButton
                    launching: !!root.launching[modelData.key]

                    onLaunchRequested: root.startLaunching(modelData.key)
                }
            }

            Rectangle {
                visible: (GlobalConfig.dock.showAppsButton || (GlobalConfig.dock.showMedia && !!Players.active)) && root.dockItems.length > 0
                implicitWidth: 1
                implicitHeight: root.cellSize * 0.6
                anchors.verticalCenter: parent.verticalCenter
                color: Colours.palette.m3outlineVariant
            }

            Loader {
                active: GlobalConfig.dock.showAppsButton
                asynchronous: true
                sourceComponent: Item {
                    implicitWidth: root.cellSize
                    implicitHeight: root.cellSize

                    StateLayer {
                        radius: Tokens.rounding.large

                        onClicked: {
                            if (Config.launcher.enabled)
                                root.screenState.launcher = true;
                        }
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "apps"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.size(root.cellSize * 0.45).build()
                    }
                }
            }

            Loader {
                active: GlobalConfig.dock.showMedia && !!Players.active
                asynchronous: true
                sourceComponent: Item {
                    implicitWidth: root.cellSize
                    implicitHeight: root.cellSize

                    StateLayer {
                        radius: Tokens.rounding.full

                        onClicked: {
                            const active = Players.active;
                            if (active?.canTogglePlaying)
                                active.togglePlaying();
                        }
                    }

                    CoverArt {
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.extraSmall
                    }
                }
            }
        }
    }
}
