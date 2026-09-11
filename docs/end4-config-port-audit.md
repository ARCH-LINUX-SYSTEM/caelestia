# Audit port cấu hình end4-pC vào Caelestia

## Phạm vi và nguồn kiểm kê

Audit này chỉ xét hệ thống cấu hình và hành vi có thể tùy chỉnh. Caelestia tiếp tục là nền tảng, kiến trúc, giao diện, theme, component, branding và cấu trúc thư mục chính.

Nguồn end4-pC đã kiểm tra:

- `modules/common/Config.qml`: schema, default, load/save/reload.
- `modules/common/Appearance.qml`: token giao diện tính toán từ config.
- `modules/common/Persistent.qml`: trạng thái phiên, không phải cấu hình người dùng.
- `modules/settings/Settings.qml`, `SettingsContent.qml` và toàn bộ `pages/*.qml`: UI, enum và range.
- `services/HyprlandConfig.qml`, `scripts/hyprland/hyprconfigurator.py`: cách end4 ghi cấu hình Hyprland.
- Toàn bộ chỗ đọc `Config.options.*`, kể cả truy cập động qua tên widget.

Nguồn Caelestia đã kiểm tra:

- `plugin/src/Caelestia/Config/*`: schema typed C++, default, per-monitor overlay, load/save/reload.
- Toàn bộ chỗ đọc `GlobalConfig`, `Config`, `TokenConfig` và `Tokens`.
- Toàn bộ Nexus settings và các service/module tương ứng.
- Config live `~/.config/caelestia/shell.json`, `shell-tokens.json` và plugin live.

Kết quả:

- end4-pC có **43 nhóm top-level** và **386 tùy chọn lá**.
- Có **235 tùy chọn được tham chiếu trực tiếp trong UI settings**.
- Có **151 tùy chọn ẩn/runtime hoặc được truy cập động**; không được coi là “không dùng” chỉ vì không xuất hiện trực tiếp trong page settings.
- Caelestia hiện có **305 tùy chọn shell typed** và **119 token giao diện** trước khi hoàn tất port.

## Mã phân loại

- `EXISTING`: Caelestia đã có tùy chọn/hành vi tương đương; hợp nhất, không tạo hệ thống trùng.
- `DIRECT`: thêm được theo kiến trúc hiện tại, không cần mang kiến trúc end4 sang.
- `REWRITE`: ý tưởng áp dụng được nhưng hành vi phải viết lại cho Caelestia.
- `SCHEMA_ONLY`: Caelestia chưa có module tương ứng; thêm schema typed/default/validation an toàn nhưng không port module UI end4.
- `NOT_APPLICABLE`: tùy chọn gắn với kiến trúc end4 và sẽ không được dùng để thay đổi nền tảng Caelestia.

## Phân loại theo nhóm

| Nhóm end4 | Số lá | Phân loại | Cách tích hợp vào Caelestia |
|---|---:|---|---|
| `panelFamily` | 1 | `NOT_APPLICABLE` | Không thêm bộ chọn kiến trúc `ii/waffle`; Caelestia luôn là nền tảng chính. |
| `policies` | 2 | `SCHEMA_ONLY` | Schema cho extension AI/weeb, không bật module end4. |
| `ai` | 3 | `SCHEMA_ONLY` | Schema model/prompt typed; không copy sidebar AI, provider hay UI end4. |
| `appearance` | 22 | `EXISTING` + `DIRECT` + `REWRITE` | Hợp nhất vào `appearance`, `border`, token và bridge theme CLI hiện có. |
| `audio` | 3 | `EXISTING` | Dùng `services.audioProtection` và `services.maxVolume`, đổi đơn vị phần trăm sang tỷ lệ. |
| `profile` | 3 | `DIRECT` | Thêm profile typed và dùng ở dashboard/lock khi được bật. |
| `hyprland` | 25 | `REWRITE` | Lưu trong `shell.json`, áp dụng qua service/IPC Hyprland của Caelestia; không copy Python/Lua writer end4. |
| `apps` | 9 | `EXISTING` + `DIRECT` | Mở rộng `general.apps`; command giữ dạng danh sách argv an toàn. |
| `background` | 96 | `EXISTING` + `DIRECT` + `SCHEMA_ONLY` | Clock/visualiser/wallpaper hợp nhất; widget canvas không có module chỉ nhận schema. |
| `bar` | 54 | `EXISTING` + `REWRITE` + `SCHEMA_ONLY` | Ánh xạ vào `bar.entries`, workspaces, tray, status; không đổi Caelestia thành bar ngang end4. |
| `battery` | 5 | `EXISTING` + `REWRITE` | Ánh xạ vào `general.battery.warnLevels`, `criticalLevel`, auto-hibernate. |
| `calendar` | 1 | `DIRECT` | Locale riêng, fallback locale hệ thống. |
| `conflictKiller` | 2 | `SCHEMA_ONLY` | Default tắt; không tự ý kill daemon/tray. |
| `crosshair` | 1 | `SCHEMA_ONLY` | Không có module crosshair trong Caelestia. |
| `dock` | 12 | `SCHEMA_ONLY` | Không port dock end4 hay UI dock; schema dành cho extension tương lai. |
| `interactions` | 5 | `REWRITE` + `SCHEMA_ONLY` | Scroll factor chỉ áp dụng tại component Caelestia phù hợp; workaround mặc định tắt. |
| `language` | 4 | `REWRITE` + `SCHEMA_ONLY` | Locale UI theo Qt/Caelestia; translator chỉ có schema vì chưa có module. |
| `launcher` | 1 | `EXISTING` | Ánh xạ `pinnedApps` sang `launcher.favouriteApps`. |
| `light` | 5 | `SCHEMA_ONLY` | Không copy night-light/anti-flashbang module end4. |
| `lock` | 13 | `EXISTING` + `REWRITE` | Mở rộng lock hiện có; backend Hyprlock và security luôn opt-in. |
| `media` | 1 | `DIRECT` | Lọc player trùng trong `services/Players.qml`. |
| `networking` | 1 | `DIRECT` | User-Agent cấu hình cho request do Caelestia quản lý. |
| `notifications` | 1 | `EXISTING` | Ánh xạ vào `notifs.defaultExpireTimeout`. |
| `osd` | 1 | `EXISTING` | Ánh xạ vào `osd.hideDelay`. |
| `osk` | 2 | `SCHEMA_ONLY` | Không có bàn phím ảo tương ứng. |
| `overlay` | 5 | `SCHEMA_ONLY` | Không copy overlay canvas/floating image end4. |
| `overview` | 8 | `REWRITE` | Chỉ áp dụng phần phù hợp vào WindowSwitcher; không copy overview end4. |
| `regionSelector` | 11 | `REWRITE` | Mở rộng AreaPicker bằng component và style Caelestia. |
| `resources` | 2 | `EXISTING` + `DIRECT` | Interval vào dashboard; history length bổ sung cho model thống kê. |
| `tray` | 5 | `EXISTING` + `REWRITE` | Hợp nhất với `bar.tray`, không tạo tray thứ hai. |
| `musicRecognition` | 2 | `SCHEMA_ONLY` | Caelestia chưa có module nhận diện nhạc. |
| `search` | 16 | `EXISTING` + `REWRITE` + `SCHEMA_ONLY` | Prefix app/action hợp nhất launcher; provider chưa có chỉ nhận schema. |
| `sidebar` | 28 | `EXISTING` + `REWRITE` + `SCHEMA_ONLY` | Hover/quick toggles/media hợp nhất; AI/booru/translator không được copy. |
| `custom` | 2 | `EXISTING` | Ánh xạ logo và recolour hiện có. |
| `screenRecord` | 1 | `DIRECT` | Thêm đường dẫn lưu cho Recorder hiện có. |
| `screenSnip` | 1 | `DIRECT` | Thêm đường dẫn lưu cho AreaPicker hiện có. |
| `sounds` | 3 | `SCHEMA_ONLY` | Không thêm sound daemon; default tắt. |
| `time` | 9 | `DIRECT` + `SCHEMA_ONLY` | Format/second precision dùng service Time; Pomodoro chỉ schema vì không có module. |
| `updates` | 4 | `SCHEMA_ONLY` | Giữ trang Update của Caelestia; không copy updater end4. |
| `wallpaperSelector` | 8 | `EXISTING` + `DIRECT` | Mở rộng Nexus wallpaper selector. |
| `windows` | 2 | `DIRECT` | Áp dụng cho window chrome do Caelestia sở hữu. |
| `hacks` | 1 | `SCHEMA_ONLY` | Chỉ compatibility field typed; không chèn delay vào luồng mặc định. |
| `workSafety` | 5 | `SCHEMA_ONLY` | Không copy automation giám sát clipboard/network; default tắt. |

## Kiểm kê đầy đủ 386 tùy chọn

Mỗi mục dưới đây là đường dẫn đầy đủ trong `Config.options` của end4-pC.

```text
panelFamily
policies.ai
policies.weeb
ai.systemPrompt
ai.tool
ai.extraModels
appearance.extraBackgroundTint
appearance.fakeScreenRounding
appearance.fonts.main
appearance.fonts.numbers
appearance.fonts.title
appearance.fonts.iconNerd
appearance.fonts.monospace
appearance.fonts.reading
appearance.fonts.expressive
appearance.transparency.enable
appearance.transparency.automatic
appearance.transparency.backgroundTransparency
appearance.transparency.contentTransparency
appearance.wallpaperTheming.enableAppsAndShell
appearance.wallpaperTheming.enableQtApps
appearance.wallpaperTheming.enableTerminal
appearance.wallpaperTheming.terminalGenerationProps.harmony
appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold
appearance.wallpaperTheming.terminalGenerationProps.termFgBoost
appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode
appearance.palette.type
appearance.palette.accentColor
audio.protection.enable
audio.protection.maxAllowedIncrease
audio.protection.maxAllowed
profile.avatarPath
profile.avatarPicture
profile.descriptionText
hyprland.animations.animation
hyprland.animations.enable
hyprland.autostartApps.enable
hyprland.autostartApps.apps
hyprland.decoration.rounding
hyprland.decoration.activeOpacity
hyprland.decoration.inactiveOpacity
hyprland.decoration.blur.enabled
hyprland.decoration.blur.size
hyprland.decoration.blur.passes
hyprland.decoration.shadow.enabled
hyprland.decoration.shadow.range
hyprland.general.borderSize
hyprland.general.gapsIn
hyprland.general.gapsOut
hyprland.general.layout
hyprland.input.kbLayout
hyprland.input.numlock
hyprland.input.repeatDelay
hyprland.input.repeatRate
hyprland.input.followMouse
hyprland.input.touchpad.naturalScroll
hyprland.input.touchpad.disableWhileTyping
hyprland.input.touchpad.clickfingerBehavior
hyprland.input.touchpad.scrollFactor
apps.bluetooth
apps.changePassword
apps.network
apps.manageUser
apps.networkEthernet
apps.taskManager
apps.terminal
apps.update
apps.volumeMixer
background.widgetsLocked
background.widgets.clock.enable
background.widgets.clock.showOnlyWhenLocked
background.widgets.clock.placementStrategy
background.widgets.clock.x
background.widgets.clock.y
background.widgets.clock.style
background.widgets.clock.styleLocked
background.widgets.clock.cookie.aiStyling
background.widgets.clock.cookie.sides
background.widgets.clock.cookie.dialNumberStyle
background.widgets.clock.cookie.hourHandStyle
background.widgets.clock.cookie.minuteHandStyle
background.widgets.clock.cookie.secondHandStyle
background.widgets.clock.cookie.dateStyle
background.widgets.clock.cookie.timeIndicators
background.widgets.clock.cookie.hourMarks
background.widgets.clock.cookie.dateInClock
background.widgets.clock.cookie.constantlyRotate
background.widgets.clock.cookie.useSineCookie
background.widgets.clock.digital.adaptiveAlignment
background.widgets.clock.digital.showDate
background.widgets.clock.digital.animateChange
background.widgets.clock.digital.vertical
background.widgets.clock.digital.font.family
background.widgets.clock.digital.font.weight
background.widgets.clock.digital.font.width
background.widgets.clock.digital.font.size
background.widgets.clock.digital.font.roundness
background.widgets.clock.quote.enable
background.widgets.clock.quote.text
background.widgets.clock.quote.followClock
background.widgets.weather.enable
background.widgets.weather.placementStrategy
background.widgets.weather.x
background.widgets.weather.y
background.widgets.weather.sizeMode
background.widgets.calendar.enable
background.widgets.calendar.placementStrategy
background.widgets.calendar.x
background.widgets.calendar.y
background.widgets.calendar.sizeMode
background.widgets.worldClock.enable
background.widgets.worldClock.timezones
background.widgets.worldClock.placementStrategy
background.widgets.worldClock.x
background.widgets.worldClock.y
background.widgets.worldClock.sizeMode
background.widgets.userCard.enable
background.widgets.userCard.placementStrategy
background.widgets.userCard.x
background.widgets.userCard.y
background.widgets.images.enable
background.widgets.images.placementStrategy
background.widgets.images.x
background.widgets.images.y
background.widgets.visualizer.enable
background.widgets.visualizer.placementStrategy
background.widgets.visualizer.x
background.widgets.visualizer.y
background.widgets.customImage.enable
background.widgets.customImage.placementStrategy
background.widgets.customImage.x
background.widgets.customImage.y
background.widgets.customImage.path
background.widgets.customImage.shape
background.widgets.customImage.size
background.widgets.resources.enable
background.widgets.resources.placementStrategy
background.widgets.resources.x
background.widgets.resources.y
background.widgets.resources.vertical
background.widgets.media.enable
background.widgets.media.showControls
background.widgets.media.showLyrics
background.widgets.media.showTitles
background.widgets.media.backgroundShape
background.widgets.media.placementStrategy
background.widgets.media.x
background.widgets.media.y
background.screenList
background.wallpaperPath
background.centeredWallpaper
background.centeredWallpaperShape
background.centeredWallpaperSize
background.centeredWallpaperColor
background.centeredWallpaperOnlyWhenLocked
background.wallpaperAnimation
background.thumbnailPath
background.hideWhenFullscreen
background.parallax.vertical
background.parallax.autoVertical
background.parallax.enableWorkspace
background.parallax.workspaceZoom
background.parallax.enableSidebar
background.parallax.widgetsFactor
bar.autoHide.enable
bar.autoHide.hoverRegionWidth
bar.autoHide.pushWindows
bar.autoHide.showWhenPressingSuper.enable
bar.autoHide.showWhenPressingSuper.delay
bar.bottom
bar.cornerStyle
bar.floatStyleShadow
bar.borderless
bar.topLeftIcon
bar.showBackground
bar.verbose
bar.vertical
bar.resources.style
bar.resources.showValue
bar.resources.alwaysShowSwap
bar.resources.alwaysShowCpu
bar.resources.alwaysShowCpuTemp
bar.resources.alwaysShowDisk
bar.resources.alwaysShowRam
bar.resources.memoryWarningThreshold
bar.resources.swapWarningThreshold
bar.resources.cpuWarningThreshold
bar.layouts.leftLayout
bar.layouts.middleLayout
bar.layouts.rightLayout
bar.screenList
bar.utilButtons.showScreenSnip
bar.utilButtons.showColorPicker
bar.utilButtons.showMicToggle
bar.utilButtons.showKeyboardToggle
bar.utilButtons.showWallpaperToggle
bar.utilButtons.showDarkModeToggle
bar.utilButtons.showPerformanceProfileToggle
bar.utilButtons.showScreenRecord
bar.utilButtons.isRecording
bar.workspaces.monochromeIcons
bar.workspaces.shown
bar.workspaces.showAppIcons
bar.workspaces.indicatorStyle
bar.workspaces.alwaysShowNumbers
bar.workspaces.showNumberDelay
bar.workspaces.numberMap
bar.workspaces.useNerdFont
bar.weather.enable
bar.weather.enableGPS
bar.weather.city
bar.weather.useUSCS
bar.weather.fetchInterval
bar.indicators.notifications.showUnreadCount
bar.tooltips.clickToShow
bar.media.preferredPlayer
bar.media.alwaysVisible
bar.media.onlyTitle
battery.low
battery.critical
battery.full
battery.automaticSuspend
battery.suspend
calendar.locale
conflictKiller.autoKillNotificationDaemons
conflictKiller.autoKillTrays
crosshair.code
dock.enable
dock.showBackground
dock.showPinButton
dock.showAppsButton
dock.showMedia
dock.monochromeIcons
dock.height
dock.hoverRegionHeight
dock.pinnedOnStartup
dock.hoverToReveal
dock.pinnedApps
dock.ignoredAppRegexes
interactions.scrolling.fasterTouchpadScroll
interactions.scrolling.mouseScrollDeltaThreshold
interactions.scrolling.mouseScrollFactor
interactions.scrolling.touchpadScrollFactor
interactions.deadPixelWorkaround.enable
language.ui
language.translator.engine
language.translator.targetLanguage
language.translator.sourceLanguage
launcher.pinnedApps
light.night.automatic
light.night.from
light.night.to
light.night.colorTemperature
light.antiFlashbang.enable
lock.useHyprlock
lock.launchOnStartup
lock.showWidgets
lock.showMedia
lock.blur.enable
lock.blur.radius
lock.blur.extraZoom
lock.blur.size
lock.centerClock
lock.showLockedText
lock.security.unlockKeyring
lock.security.requirePasswordToPower
lock.materialShapeChars
media.filterDuplicatePlayers
networking.userAgent
notifications.timeout
osd.timeout
osk.layout
osk.pinnedOnStartup
overlay.openingZoomAnimation
overlay.darkenScreen
overlay.clickthroughOpacity
overlay.floatingImage.imageSource
overlay.floatingImage.scale
overview.enable
overview.style
overview.scale
overview.rows
overview.columns
overview.orderRightLeft
overview.orderBottomUp
overview.centerIcons
regionSelector.targetRegions.windows
regionSelector.targetRegions.layers
regionSelector.targetRegions.content
regionSelector.targetRegions.showLabel
regionSelector.targetRegions.opacity
regionSelector.targetRegions.contentRegionOpacity
regionSelector.targetRegions.selectionPadding
regionSelector.rect.showAimLines
regionSelector.circle.strokeWidth
regionSelector.circle.padding
regionSelector.annotation.useSatty
resources.updateInterval
resources.historyLength
tray.monochromeIcons
tray.showItemId
tray.invertPinnedItems
tray.pinnedItems
tray.filterPassive
musicRecognition.timeout
musicRecognition.interval
search.nonAppResultDelay
search.engineBaseUrl
search.excludedSites
search.sloppy
search.prefix.showDefaultActionsWithoutPrefix
search.prefix.action
search.prefix.app
search.prefix.clipboard
search.prefix.emojis
search.prefix.keybinds
search.prefix.symbols
search.prefix.math
search.prefix.shellCommand
search.prefix.webSearch
search.imageSearch.imageSearchEngineBaseUrl
search.imageSearch.useCircleSelection
sidebar.banner
sidebar.bannerImage
sidebar.keepRightSidebarLoaded
sidebar.translator.enable
sidebar.translator.delay
sidebar.media.enable
sidebar.media.artColors
sidebar.ai.textFadeIn
sidebar.booru.allowNsfw
sidebar.booru.defaultProvider
sidebar.booru.limit
sidebar.booru.zerochan.username
sidebar.cornerOpen.enable
sidebar.cornerOpen.bottom
sidebar.cornerOpen.valueScroll
sidebar.cornerOpen.clickless
sidebar.cornerOpen.cornerRegionWidth
sidebar.cornerOpen.cornerRegionHeight
sidebar.cornerOpen.visualize
sidebar.cornerOpen.clicklessCornerEnd
sidebar.cornerOpen.clicklessCornerVerticalOffset
sidebar.quickToggles.style
sidebar.quickToggles.android.columns
sidebar.quickToggles.android.toggles
sidebar.quickSliders.enable
sidebar.quickSliders.showMic
sidebar.quickSliders.showVolume
sidebar.quickSliders.showBrightness
custom.distroIcon
custom.colorizeIcon
screenRecord.savePath
screenSnip.savePath
sounds.battery
sounds.pomodoro
sounds.theme
time.format
time.shortDateFormat
time.dateWithYearFormat
time.dateFormat
time.pomodoro.breakTime
time.pomodoro.cyclesBeforeLongBreak
time.pomodoro.focus
time.pomodoro.longBreak
time.secondPrecision
updates.enableCheck
updates.checkInterval
updates.adviseUpdateThreshold
updates.stronglyAdviseUpdateThreshold
wallpaperSelector.useSystemFileDialog
wallpaperSelector.showBlurBackground
wallpaperSelector.showHomePath
wallpaperSelector.userPath
wallpaperSelector.showSearchbar
wallpaperSelector.columns
wallpaperSelector.closeAfterSelection
wallpaperSelector.changeInterval
windows.showTitlebar
windows.centerTitle
hacks.arbitraryRaceConditionDelay
workSafety.enable.wallpaper
workSafety.enable.clipboard
workSafety.triggerCondition.networkNameKeywords
workSafety.triggerCondition.fileKeywords
workSafety.triggerCondition.linkKeywords
```

## Thiết kế tích hợp

### Persistence và tương thích ngược

- Giữ `~/.config/caelestia/shell.json` và `shell-tokens.json`.
- Giữ per-monitor overlay hiện có.
- Thêm `configVersion` và migration trước validation.
- Config cũ không có version được xem là version `0`, chỉ bổ sung/đổi khóa có ánh xạ rõ ràng.
- Không ghi default mới vào file nếu người dùng chưa override.
- Giữ unknown keys như cơ chế hiện tại để config từ bản mới hơn không bị mất.
- Không tự động import `~/.config/illogical-impulse/config.json`; import end4 nếu có sẽ là thao tác chủ động và có preview.

### Validation

- Giữ kiểm tra kiểu chặt hiện có.
- Bổ sung hook validation theo property cho range, enum, URL/time format và shape của `QVariantList`.
- File sai schema không trở thành baseline save và không ghi đè config hợp lệ.
- UI giới hạn cùng range với backend; backend vẫn là nguồn kiểm tra cuối cùng.

### Hành vi

- Setting đã có tiếp tục dùng component/service Caelestia.
- Setting Hyprland được lưu trong config Caelestia và áp dụng bằng IPC/service của Caelestia; không ghi Lua bằng script end4.
- Setting không có consumer giữ default an toàn và không thay đổi giao diện/runtime.
- Mọi tính năng mới mặc định tắt hoặc giữ đúng hành vi hiện tại của Caelestia.

## File dự kiến sửa

Config framework:

- `plugin/src/Caelestia/Config/configobject.hpp`
- `plugin/src/Caelestia/Config/configobject.cpp`
- `plugin/src/Caelestia/Config/rootconfig.hpp`
- `plugin/src/Caelestia/Config/rootconfig.cpp`
- `plugin/src/Caelestia/Config/config.hpp`
- `plugin/src/Caelestia/Config/config.cpp`
- `plugin/src/Caelestia/Config/CMakeLists.txt`

Schema hiện có được mở rộng:

- `appearanceconfig.hpp`
- `backgroundconfig.hpp`
- `barconfig.hpp`
- `dashboardconfig.hpp`
- `generalconfig.hpp`
- `launcherconfig.hpp`
- `lockconfig.hpp`
- `nexusconfig.hpp`
- `notifsconfig.hpp`
- `osdconfig.hpp`
- `serviceconfig.hpp`
- `sidebarconfig.hpp`
- `utilitiesconfig.hpp`
- `winfoconfig.hpp`
- `userpaths.hpp`

Runtime consumer dự kiến:

- `modules/BatteryMonitor.qml`
- `services/Audio.qml`
- `services/Players.qml`
- `services/Time.qml`
- `services/Wallpapers.qml`
- `services/WallpaperPauser.qml`
- `modules/background/Background.qml`
- `modules/background/DesktopClock.qml`
- `modules/background/Visualiser.qml`
- `modules/bar/Bar.qml`
- `modules/lock/Lock.qml`
- `modules/launcher/Launcher.qml`
- `modules/sidebar/Sidebar.qml`
- `modules/areapicker/AreaPicker.qml`
- `modules/windowswitcher/WindowSwitcher.qml`

Nexus:

- `modules/nexus/PageRegistry.qml`
- `modules/nexus/PageCompRegistry.qml`
- các page hiện có trong `modules/nexus/pages/`
- các component row dùng chung trong `modules/nexus/common/`

## File dự kiến tạo

- `plugin/src/Caelestia/Config/configmigration.hpp`
- `plugin/src/Caelestia/Config/configmigration.cpp`
- `plugin/src/Caelestia/Config/hyprlandconfig.hpp`
- `plugin/src/Caelestia/Config/interactionconfig.hpp`
- `plugin/src/Caelestia/Config/searchconfig.hpp`
- `plugin/src/Caelestia/Config/captureconfig.hpp`
- `plugin/src/Caelestia/Config/optionalconfig.hpp`
- `services/HyprlandSettings.qml`
- `modules/nexus/pages/AdvancedSettings.qml`
- các subpage typed trong `modules/nexus/pages/advanced/`
- test config/migration trong `plugin/tests/`
- tài liệu schema/example trong `docs/`

Danh sách có thể được tách nhỏ thêm nhưng không được đổi hướng kiến trúc đã nêu.

## Những phần không được copy

- Không copy `modules/common/Config.qml`, `Appearance.qml` hay `Persistent.qml`.
- Không copy nguyên các page settings end4.
- Không copy widget canvas, dock, overlay, overview, AI, booru, translator hay OSK module.
- Không copy `hyprconfigurator.py`, shell override Lua, preset scripts hay autostart script end4.
- Không copy theme, palette implementation, icon pack, shader, asset hoặc component giao diện end4.
- Không copy cấu trúc `modules/ii`, `modules/waffle`, tên `illogical-impulse`, branding hay đường dẫn config end4.
- Không chuyển state phiên trong `Persistent.qml` thành user config nếu Caelestia đã có state/service riêng.

