# Integration Notes

Record shared contracts, config decisions, migrations, and settings integration
needed by this worker or another parallel worker. Keep this file current while
implementing the task.

## Shared or config changes

- Added a macOS-style Dock UI (`modules/dock/`) that consumes the existing,
  previously-`SCHEMA_ONLY` `dock.*` config tree (`plugin/src/Caelestia/Config/optionalconfig.hpp`,
  `DockConfig`). No C++/schema/default/migration changes were needed: the
  schema, defaults, range/regex validators and the `dock.enable` ->
  `dock.enabled` migration already existed
  (`plugin/src/Caelestia/Config/configmigration.cpp:450`). `dock.enabled`
  defaults to `false`, so this feature is fully opt-in and no existing user
  sees any behaviour change after updating.
- **Important for any worker touching `Caelestia.Config`**: `dock.*` fields
  are `CONFIG_GLOBAL_PROPERTY` and are *not* in the per-screen `Config`
  attached-property whitelist (`plugin/src/Caelestia/Config/configattached.{hpp,cpp}`).
  Read and write them via the `GlobalConfig` singleton
  (`GlobalConfig.dock.foo`), not `Config.dock.foo` — the latter does not
  compile/lint (`qmllint` gave `Member "dock" not found on type
  caelestia::config::Config`). This applies to every other `SCHEMA_ONLY`
  section too (`hyprland`, `interactions`, `language`, `policies`, `ai`,
  `conflictKiller`, `crosshair`, `light`, `musicRecognition`, `osk`,
  `overlay`, `overview`, `profile`, `regionSelector`, `search`, `sounds`,
  `time`, `updates`, `windows`, `hacks`, `workSafety`) — check
  `configattached.hpp`'s `Q_PROPERTY` list before assuming `Config.<section>`
  works.
- Added a "Dock" settings sub-page: `modules/nexus/pages/panels/DockPanel.qml`,
  registered in `modules/nexus/PageCompRegistry.qml` under the `panels`
  StackPage as **sub-page index 13** (indices 0-12 are already used by
  `PanelsPage`/`DashboardPanel`/`TaskbarPanel`/`LauncherPanel`/`SidebarPanel`
  and the taskbar sub-pages — see that file before adding more sub-pages to
  the `panels` StackPage, and pick index 14+ to avoid clashing with this).
  Navigation entry added to `modules/nexus/pages/PanelsPage.qml`.

- Replaced the Dashboard's "Thời tiết" (Weather) tab with a "Thông báo"
  (Notifications) tab that embeds the sidebar's existing `NotifDock`
  (`modules/sidebar/NotifDock.qml`) instead of building a second notification
  list — see `modules/dashboard/NotificationsTab.qml`.
  - **Config rename**: `dashboard.showWeather` (bool) -> `dashboard.showNotifications`
    (bool, still default `true`) in `plugin/src/Caelestia/Config/dashboardconfig.hpp`.
    This is a straight rename (not additive), so a `shell.json` with a
    persisted `dashboard.showWeather` value will silently fall back to the
    new default (`true`) rather than carrying the old value forward — no
    migration step was added since `configmigration.cpp`'s `migrate()` table
    is for importing *other* shells' config shapes into Caelestia's own
    schema, not for renames within Caelestia's own schema; flag this if a
    later worker wants stricter continuity here.
  - Updated the two other call sites: `modules/dashboard/Content.qml` (tab
    definition) and `modules/nexus/pages/panels/DashboardPanel.qml` (Settings
    toggle, still last in the "Thẻ" section).
  - Deleted `modules/dashboard/WeatherTab.qml` (now fully unreferenced; the
    `Weather` service and `SmallWeather`/lock-screen weather widgets are
    untouched and still used elsewhere).
  - `NotificationsTab.qml` gives itself its own `Props { reloadableId:
    "dashboardNotifs" }` instance (distinct from the sidebar's own
    `"sidebar"`-id `Props`), so expanding/collapsing a notification group in
    the dashboard tab doesn't share state with the sidebar's notification
    list. Declared as `property var props` rather than `property Props
    props` — see the comment in the file; typing it `Props` produces a
    qmllint `incompatible-type` false positive because the type reached via
    this file's `import qs.modules.sidebar` is treated as nominally distinct
    from the one `NotifDock.qml` resolves via its own directory's implicit
    import, even though both are the same underlying `Props.qml`. Confirmed
    this doesn't affect runtime binding (QML property assignment isn't
    checked by declared static type), only static lint.

## Shared interfaces and integration points

- The Dock is a **standalone overlay window** (`modules/dock/DockWindow.qml`,
  one instance per screen via `Variants` in `modules/dock/Dock.qml`), not a
  child of the shared `modules/drawers/ContentWindow.qml`. It does not touch
  `ContentWindow`, `Panels`, `Interactions`, `Regions`, `Bar`/`BarWrapper`, or
  the blob-deform system, so it should not conflict with the Launcher /
  System Tools / Control Center workers' changes to those files.
- Layer-shell namespace: `caelestia-dock` (via `StyledWindow.name: "dock"`).
  `WlrLayershell.exclusionMode` is `Ignore`, matching the rest of the shell's
  overlay windows (`ContentWindow`, `WindowSwitcher`) — the dock never
  reserves screen space / never tiles windows around itself.
- The window is anchored `bottom: true` only, so Hyprland's layer-shell
  centers it horizontally; width is always the natural content width (icons
  never reflow between hidden/revealed states), only height animates. When
  "hidden", the window shrinks to `GlobalConfig.dock.hoverRegionHeight` (not
  to 0) so it stays hoverable and can trigger its own reveal — there is no
  separate full-width hover-trigger surface.
- Reused existing services/components instead of duplicating them:
  `qs.modules.launcher.services.Apps` (launch), `qs.services.Hypr`
  (toplevels/focus dispatch), `qs.services.Players` +
  `qs.components.widgets.CoverArt` (now-playing widget), `qs.services.ShellState`
  (`ScreenState.launcher` toggle for the dock's "open launcher" button),
  `qs.components.effects.ColouredIcon` (monochrome icon option), Quickshell's
  built-in `DesktopEntries.byId` / `DesktopEntries.heuristicLookup` (same
  heuristic `utils/Icons.qml` already relies on) for matching running window
  classes to desktop entries/pinned app ids.
- Fullscreen-awareness is computed locally in `DockWindow.qml`
  (`hasFullscreen`, checking the dock's own monitor's active workspace) since
  the dock has no access to `ContentWindow`'s shared `hasFullscreen`. If a
  future refactor wants a single shared "is this monitor showing a
  fullscreen window" helper, this is a second call site that would benefit.
- No new IPC handlers or shortcuts were added for the dock (kept scope
  minimal); if another worker needs to programmatically show/focus the dock,
  say so here first rather than adding a second dock-toggle mechanism.
- Focusing a running window from `DockIcon.activate()` reuses the exact same
  `Hypr.dispatch` focus call as `modules/windowswitcher/WindowSwitcher.qml`
  (`focuswindow <selector>` / `hl.dsp.focus({ window = ... })` on Lua
  configs). On a stock Hyprland config (`cursor:no_warps` unset / `false`,
  the default), that dispatcher warps the mouse cursor to the center of the
  window being focused — visible as the cursor "jumping" to the middle of
  the screen whenever a running app's dock icon is clicked. This is a
  Hyprland compositor behaviour, not something fixable from the dock's QML;
  confirmed via `hyprctl cursorpos` before/after `hyprctl dispatch
  'hl.dsp.focus({ window = "address:..." })'` that setting `cursor.no_warps
  = true` (Lua: `hl.config({ cursor = { no_warps = true } })`) eliminates
  the warp with no other observed side effects, and it also fixes the same
  warp for the (out-of-scope) window switcher since both share the call
  site pattern. Users enabling the dock should be pointed at this setting;
  it is a one-line addition to their own `hyprland.lua`/`hyprland.conf`, not
  something this worktree's shell ships or can set on the user's behalf.
- Added a macOS-style launch bounce to `DockIcon.qml`: clicking a pinned
  app's icon that has no running window plays a repeating rise/fall
  (`SequentialAnimation`, `Easing.OutQuad` up / `Easing.InQuad` down, ~940ms
  per cycle) via a `Translate` in `transform`, independent of the existing
  hover-magnification `scale`. Only triggers on the actual launch branch of
  `DockIcon.activate()` (`Apps.launch(...)`), not on focusing an
  already-running window — matches real macOS (no bounce on simple
  activation).
  - Launch state lives in `DockWindow.qml` as `launching` (a `{key:
    timestampMs}` map keyed by the same stable `modelData.key` —
    `pinned:<id>` / `running:<key>` — `computeDockItems()` already uses),
    not on the `DockIcon` delegate itself: `Repeater { model: root.dockItems
    }` recreates all delegates whenever the array changes (e.g. any window
    opening/closing anywhere recomputes `dockItems`), so per-delegate state
    would be silently wiped mid-bounce on unrelated toplevel churn.
  - Stops as soon as `onDockItemsChanged` sees that key's `addresses.length
    > 0` (its window mapped), or after `launchTimeoutMs` (8s, pruned by a
    1s `Timer` gated on `anyLaunching`) if the app never maps a window
    (already running as a background/tray process, crashes, etc.).
  - `DockWindow.implicitHeight` gains `bounceHeadroom` (`cellSize * 0.5`)
    while `anyLaunching` is true, animated via the existing `Behavior on
    implicitHeight`. Needed because the dock is a real Wayland layer-shell
    surface sized to fit the resting icon row — unlike macOS's Dock, there
    is no surrounding desktop surface for the icon to overflow into, so
    without the extra headroom the bounce would be clipped by `clipWrap`'s
    `clip: true` at the window's own edge.
- Fixed a pre-existing bug (never caught before because the dock had never
  been visually/interactively tested per the note below): the pin button
  would flicker and miss clicks. Cause: `Repeater { model: root.dockItems }`
  bound directly to the array `computeDockItems()` returns — a brand new
  array on every recompute (any toplevel opening/closing anywhere, not just
  a pin toggle, reruns it). QML can't diff one JS array instance against
  another, so Repeater treated every recompute as "the model changed" and
  destroyed + recreated **every** `DockIcon` delegate, dropping hover state
  mid-click and, since pinning moves an item to the front of the list,
  leaving the next click aimed at empty space or a different icon. Fixed by
  switching to `model: root.dockItems.length` with `modelData:
  root.dockItems[index]` bound explicitly (`index` declared `required` on
  the delegate instantiation, not inside `DockIcon.qml` itself, since only
  `DockWindow.qml` needs it) — existing delegates are now reused and just
  receive new property values, so reordering swaps each slot's *content*
  instantly rather than sliding the icon (no delegate destruction, but also
  no move animation to reuse for it; a `Row.move` transition was tried and
  removed since it can't fire when children never actually change index).
  If a future worker wants animated slides on reorder instead, that needs a
  real keyed model (e.g. `DelegateModel` with stable per-app groups), not a
  small tweak — flag it here first rather than re-introducing the
  array-model regression.

## Migration and compatibility notes

- No migration needed beyond the pre-existing `dock.enable` ->
  `dock.enabled` rename in `configmigration.cpp`.
- `dock.enabled` defaults to `false` (unchanged from the existing schema
  default), so existing `shell.json` files are unaffected until a user opts
  in via Settings -> Bảng -> Dock.

## Optional dependencies and graceful-degradation behavior

- Pinned apps with no matching installed `DesktopEntry`
  (`DesktopEntries.byId(id)` returns `null`) still render (using the
  fallback icon) but can only be focused if already running, not launched —
  no crash/hard dependency on the app being installed.
- The "now playing" dock item (`GlobalConfig.dock.showMedia`) is entirely
  gated on `Players.active` being non-null; with no MPRIS player running the
  item and its divider simply don't render.
- `GlobalConfig.dock.ignoredAppRegexes` entries are validated as regex by the
  C++ config layer already; the QML side additionally wraps
  `new RegExp(pattern)` in try/catch so a pattern that somehow becomes
  invalid at runtime is skipped instead of throwing.

## Build and test evidence

- Dashboard notifications-tab / `dashboard.showWeather` -> `showNotifications`
  rename:
  - `rm -rf build && cmake -B build -G Ninja && cmake --build build` — clean
    full rebuild succeeds; verified `build/qml/Caelestia/Config/caelestia-config.qmltypes`
    contains `showNotifications` (and no longer `showWeather`) on
    `DashboardConfig`.
  - `ctest --test-dir build --output-on-failure` — `caelestia-config-tests`
    passes (12/12).
  - `qmlformat` — no diff on any changed/added file.
  - `python3 scripts/qml-lint-conventions.py` — zero violations introduced.
  - `qmllint --import disable` (CI's invocation, via a regenerated
    `.qmlls.ini`) — flags `Config.dashboard.showNotifications` as
    `missing-property` on `DashboardPanel.qml`/`Content.qml` in *this dev
    sandbox only*. Root-caused to this machine's `qmllint` resolving
    `Caelestia.Config` against a stale, separately-installed system copy at
    `/usr/lib/qt6/qml/Caelestia/Config/` (from an existing AUR
    `caelestia-shell` install on this box, unrelated to this git worktree) —
    confirmed by isolating the check to `-I build/qml` alone (no system path,
    no Quickshell VFS cache) against a minimal standalone `.qml` file:
    `showNotifications` still isn't found while a pre-existing, untouched
    sibling property (`showMedia`) resolves fine in the same file, which is
    only explainable by a plugin-loading fallback to a pre-rename binary, not
    a problem with the freshly-built `build/qml` module itself (whose raw
    `.qmltypes` text is byte-confirmed correct, see above). CI's container
    has no such pre-existing competing install, so this shouldn't reproduce
    there — but flagging it here in case a future worker hits the same
    warning class and wants to double check.
  - Not done (needs a live Hyprland session): visual/interactive testing of
    the new tab's notification list, expand/collapse, and clear-all inside
    the dashboard.
- Dock feature (unchanged from previous entry, included for continuity):
  `cmake --build build` — succeeds (no C++ was changed by this feature; ran
  to confirm the pre-existing `dock` schema/build is healthy).
- `ctest --output-on-failure` (in `build/`) — `caelestia-config-tests`
  passes.
- `qmlformat` — no diff on any changed/added file.
- `python3 scripts/qml-lint-conventions.py` — zero violations introduced
  (pre-existing violations in `shell.qml` line 22-23 predate this change and
  were left untouched, out of this worker's scope).
- `qmllint --import disable` (same invocation as `.github/workflows/*lint*.yml`,
  using the regenerated `build/qml` types) — zero warnings/errors on the new
  and modified files, and a full-repo sweep (matching CI's file list, i.e.
  excluding `build/` and `modules/controlcenter/`) shows the same 44
  pre-existing warnings as before this change, none of them in files touched
  here.
- Not done (needs a live Hyprland session; did not want to spawn a second,
  overlapping full shell instance on the user's real desktop without asking
  first): visual/interactive testing of hover-reveal, magnification, pin
  toggling, and app launching/focusing. Recommend testing with
  `qs -p /home/haidangphan/caelestia` (or via whatever worktree test flow
  this project's orchestration normally uses) before merging.
