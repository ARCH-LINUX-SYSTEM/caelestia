pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.images
import qs.services
import qs.utils
import qs.modules.nexus
import qs.modules.dashboard.dash as DashboardDash
import qs.modules.dashboard.media as DashboardMedia

Item {
    id: root

    readonly property color accentColour: Colours.palette.m3primaryContainer
    readonly property real canvasX: Math.max(0, (width - 1920 * designScale) / 2)
    readonly property real canvasY: Math.max(0, (height - 1080 * designScale) / 2)
    readonly property color cardColour: Colours.palette.m3surfaceContainer
    readonly property color cardColourHigh: Colours.palette.m3surfaceContainerHigh
    readonly property real cardOpacity: 0.82
    property string convertFormat: "WEBP"
    property string convertOutput
    property string convertStatus: qsTr("Thả ảnh vào đây")
    readonly property real designScale: Math.min(width / 1920, height / 1080)
    readonly property color mutedColour: Colours.palette.m3onSurfaceVariant
    readonly property color onAccentColour: Colours.palette.m3onPrimaryContainer
    readonly property color outlineColour: Colours.palette.m3outline
    readonly property real safeLeft: ShellState.componentsFor(screen)?.bar?.exclusiveZone ?? 52
    required property ShellScreen screen
    readonly property var screenState: ShellState.forScreen(screen)
    readonly property color textColour: Colours.palette.m3onSurface
    property var worldTimes: ({
            "Sydney": ["--:--", "AEST"],
            "Tokyo": ["--:--", "JST"],
            "London": ["--:--", "BST"],
            "New York": ["--:--", "EDT"]
        })

    function convertFirstUrl(urls: var): bool {
        if (!urls || urls.length === 0 || converter.running)
            return false;

        const sourceUrl = String(urls[0]);
        if (!sourceUrl.startsWith("file://")) {
            convertStatus = qsTr("Chỉ hỗ trợ tệp ảnh cục bộ");
            return false;
        }

        const input = Paths.toLocalFile(urls[0]);
        const extension = input.slice(input.lastIndexOf(".") + 1).toLowerCase();
        const supported = ["png", "jpg", "jpeg", "webp", "avif", "bmp", "tif", "tiff", "gif"];
        if (!input || !supported.includes(extension)) {
            convertStatus = qsTr("Định dạng ảnh chưa được hỗ trợ");
            return false;
        }

        const slash = input.lastIndexOf("/");
        const dot = input.lastIndexOf(".");
        const base = dot > slash ? input.slice(0, dot) : input;
        const suffix = convertFormat.toLowerCase();
        const stamp = Qt.formatDateTime(new Date(), "yyyyMMdd_HHmmss");
        convertOutput = `${base}_caelestia_${stamp}.${suffix}`;
        convertStatus = qsTr("Đang chuyển sang %1…").arg(convertFormat);

        let args = ["-hide_banner", "-loglevel", "error", "-n", "-i", input, "-frames:v", "1"];
        if (convertFormat === "WEBP")
            args.push("-quality", "90");
        else if (convertFormat === "JPG")
            args.push("-q:v", "2");
        args.push(convertOutput);
        converter.command = ["sh", "-c", "command -v ffmpeg >/dev/null 2>&1 || exit 127; exec ffmpeg \"$@\"", "caelestia-converter", ...args];
        converter.running = true;
        return true;
    }
    function cycleConvertFormat(): void {
        const formats = ["WEBP", "PNG", "JPG"];
        const index = formats.indexOf(convertFormat);
        convertFormat = formats[(index + 1) % formats.length];
    }
    function formatPercent(value: real): string {
        return `${Math.round(Math.max(0, Math.min(1, value)) * 100)}%`;
    }

    Component.onCompleted: Weather.reload()

    ServiceRef {
        service: Cpu
    }
    ServiceRef {
        service: Memory
    }
    ServiceRef {
        service: Storage
    }
    Timer {
        interval: 1000
        repeat: true
        running: Players.active?.isPlaying ?? false

        onTriggered: Players.active?.positionChanged()
    }
    Timer {
        interval: 30000
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: {
            if (!worldClockProcess.running)
                worldClockProcess.running = true;
        }
    }
    Process {
        id: worldClockProcess

        command: ["sh", "-c", "fmt='" + (GlobalConfig.services.useTwelveHourClock ? "%I:%M %p" : "%H:%M") + "'; for spec in 'Sydney|Australia/Sydney' 'Tokyo|Asia/Tokyo' 'London|Europe/London' 'New York|America/New_York'; do name=${spec%%|*}; zone=${spec#*|}; printf '%s|' \"$name\"; TZ=\"$zone\" date \"+$fmt|%Z\"; done"]

        stdout: StdioCollector {
            onStreamFinished: {
                const next = Object.assign({}, root.worldTimes);
                const lines = text.trim().split("\n");
                for (const line of lines) {
                    const parts = line.split("|");
                    if (parts.length >= 3)
                        next[parts[0]] = [parts[1], parts[2]];
                }
                root.worldTimes = next;
            }
        }
    }
    Process {
        id: converter

        onExited: exitCode => { // qmllint disable signal-handler-parameters
            if (exitCode === 0) {
                root.convertStatus = qsTr("Đã lưu: %1").arg(Paths.shortenHome(root.convertOutput));
                Quickshell.execDetached(["notify-send", "-a", "Caelestia", "Chuyển ảnh hoàn tất", root.convertOutput]);
            } else {
                root.convertStatus = qsTr("Không thể chuyển ảnh");
                Quickshell.execDetached(["notify-send", "-u", "critical", "Caelestia", "Không thể chuyển ảnh bằng ffmpeg"]);
            }
        }
    }
    Item {
        id: canvas

        height: 1080
        scale: root.designScale
        transformOrigin: Item.TopLeft
        width: 1920
        x: root.canvasX
        y: root.canvasY

        Item {
            id: clockBlock

            height: 178
            width: 440
            x: Math.max(86, root.safeLeft / Math.max(root.designScale, 0.01) + 28)
            y: 158

            StyledText {
                id: largeClock

                anchors.left: parent.left
                anchors.top: parent.top
                color: root.textColour
                font: Tokens.font.clock.size(Tokens.font.headline.large.pointSize * 2.4).weight(Font.Bold).build()
                text: `${Time.hourStr}:${Time.minuteStr}`
            }
            Rectangle {
                border.color: Qt.alpha(root.outlineColour, 0.35)
                border.width: 1
                color: Qt.alpha(root.accentColour, 0.74)
                height: 30
                radius: height / 2
                width: dateLine.implicitWidth + 22
                x: 0
                y: 111

                StyledText {
                    id: dateLine

                    anchors.centerIn: parent
                    color: root.onAccentColour
                    font: Tokens.font.label.medium
                    text: Time.format("dddd, dd MMMM yyyy")
                }
            }
            StyledText {
                color: root.mutedColour
                font: Tokens.font.label.builders.small.letterSpacing(1.7).build()
                text: "CAELESTIA  ·  HOME"
                x: 0
                y: 153
            }
        }
        HomeCard {
            id: mediaCard

            baseColour: root.cardColour
            height: 338
            width: 440
            x: Math.max(76, root.safeLeft / Math.max(root.designScale, 0.01) + 18)
            y: 350

            Item {
                id: mediaHeader

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 116

                StyledClippingRect {
                    id: artFrame

                    anchors.left: parent.left
                    anchors.top: parent.top
                    color: Qt.alpha(root.accentColour, 0.78)
                    height: 118
                    radius: mediaCard.radius
                    width: 118

                    MaterialIcon {
                        anchors.centerIn: parent
                        color: root.onAccentColour
                        fontStyle: Tokens.font.icon.extraLarge
                        text: "graphic_eq"
                    }
                    Image {
                        anchors.fill: parent
                        asynchronous: true
                        fillMode: Image.PreserveAspectCrop
                        source: Players.getArtUrl(Players.active)
                        visible: status === Image.Ready
                    }
                }
                Column {
                    anchors.left: artFrame.right
                    anchors.leftMargin: 17
                    anchors.right: controls.left
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5

                    StyledText {
                        color: root.textColour
                        elide: Text.ElideRight
                        font: Tokens.font.title.medium
                        text: Players.active?.trackArtist || qsTr("Trình phát nhạc")
                        width: parent.width
                    }
                    StyledText {
                        color: root.mutedColour
                        elide: Text.ElideRight
                        font: Tokens.font.body.medium
                        text: Players.active?.trackTitle || qsTr("Chưa có bài hát")
                        width: parent.width
                    }
                    StyledText {
                        color: Qt.alpha(root.mutedColour, 0.72)
                        elide: Text.ElideRight
                        font: Tokens.font.label.small
                        text: Players.active?.trackAlbum || qsTr("Mở trình phát để bắt đầu")
                        width: parent.width
                    }
                }
                Column {
                    id: controls

                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 7

                    HomeAction {
                        emphasized: true
                        enabled: Players.active?.canTogglePlaying ?? false
                        icon: Players.active?.isPlaying ? "pause" : "play_arrow"

                        onClicked: Players.active?.togglePlaying()
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 6

                        HomeAction {
                            enabled: Players.active?.canGoPrevious ?? false
                            icon: "skip_previous"
                            implicitHeight: 30
                            implicitWidth: 30

                            onClicked: Players.active?.previous()
                        }
                        HomeAction {
                            enabled: Players.active?.canGoNext ?? false
                            icon: "skip_next"
                            implicitHeight: 30
                            implicitWidth: 30

                            onClicked: Players.active?.next()
                        }
                    }
                }
            }
            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: 18
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.top: mediaHeader.bottom
                color: Qt.alpha(root.outlineColour, 0.28)
                height: 1
            }
            DashboardMedia.LyricList {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.margins: 20
                anchors.right: parent.right
                anchors.top: mediaHeader.bottom
                anchors.topMargin: 16
            }
        }
        HomeCard {
            id: converterCard

            baseColour: root.cardColourHigh
            height: 252
            width: 282
            x: 1164
            y: 32

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 15
                color: root.mutedColour
                font: Tokens.font.label.builders.small.scale(0.82).letterSpacing(0.35).build()
                text: "PNG · JPG · WEBP · AVIF · BMP · TIFF"
            }
            Rectangle {
                id: dropTarget

                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.top: parent.top
                anchors.topMargin: 42
                border.color: dropArea.containsDrag ? root.onAccentColour : Qt.alpha(root.outlineColour, 0.66)
                border.width: 2
                color: dropArea.containsDrag ? Qt.alpha(root.accentColour, 0.76) : Qt.alpha(root.cardColour, 0.34)
                height: 142
                radius: 24

                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    width: parent.width - 34

                    MaterialIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: dropArea.containsDrag ? root.onAccentColour : root.mutedColour
                        fontStyle: Tokens.font.icon.large
                        text: converter.running ? "progress_activity" : "add_photo_alternate"
                    }
                    StyledText {
                        color: dropArea.containsDrag ? root.onAccentColour : root.mutedColour
                        elide: Text.ElideMiddle
                        font: Tokens.font.body.small
                        horizontalAlignment: Text.AlignHCenter
                        maximumLineCount: 2
                        text: root.convertStatus
                        width: parent.width
                        wrapMode: Text.Wrap
                    }
                }
                DropArea {
                    id: dropArea

                    anchors.fill: parent

                    onDropped: drop => {
                        if (root.convertFirstUrl(drop.urls))
                            drop.acceptProposedAction();
                    }
                }
            }
            StyledText {
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.verticalCenter: formatButton.verticalCenter
                color: root.mutedColour
                font: Tokens.font.body.small
                text: qsTr("Chuyển sang")
            }
            StyledClippingRect {
                id: formatButton

                anchors.bottom: parent.bottom
                anchors.bottomMargin: 14
                anchors.right: parent.right
                anchors.rightMargin: 16
                color: Qt.alpha(root.accentColour, 0.8)
                height: 42
                radius: height / 2
                width: 116

                Row {
                    anchors.centerIn: parent
                    spacing: 7

                    MaterialIcon {
                        color: root.onAccentColour
                        fontStyle: Tokens.font.icon.small
                        text: "sync"
                    }
                    StyledText {
                        color: root.onAccentColour
                        font: Tokens.font.label.medium
                        text: root.convertFormat
                    }
                    MaterialIcon {
                        color: root.onAccentColour
                        fontStyle: Tokens.font.icon.small
                        text: "keyboard_arrow_down"
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onClicked: root.cycleConvertFormat()
                }
            }
        }
        HomeCard {
            id: worldClockCard

            baseColour: root.cardColour
            height: 252
            width: 286
            x: 1462
            y: 32

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.top: parent.top
                anchors.topMargin: 14
                spacing: 7

                MaterialIcon {
                    color: root.mutedColour
                    fontStyle: Tokens.font.icon.small
                    text: "location_on"
                }
                StyledText {
                    color: root.mutedColour
                    font: Tokens.font.label.medium
                    text: Weather.city || qsTr("Giờ địa phương")
                }
            }
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 48
                color: root.textColour
                font: Tokens.font.headline.builders.large.weight(Font.Bold).build()
                text: Time.timeStr
            }
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 91
                color: root.mutedColour
                font: Tokens.font.body.small
                text: Time.format("dddd, dd MMMM")
            }
            Grid {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.margins: 13
                anchors.right: parent.right
                columns: 2
                spacing: 7

                Repeater {
                    model: ["Sydney", "Tokyo", "London", "New York"]

                    Rectangle {
                        required property string modelData

                        color: Qt.alpha(root.accentColour, 0.66)
                        height: 51
                        radius: 17
                        width: 126

                        StyledText {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.top: parent.top
                            anchors.topMargin: 7
                            color: root.mutedColour
                            font: Tokens.font.label.small
                            text: parent.modelData
                        }
                        StyledText {
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 6
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            color: root.onAccentColour
                            font: Tokens.font.title.small
                            text: root.worldTimes[parent.modelData]?.[0] ?? "--:--"
                        }
                        StyledText {
                            anchors.right: parent.right
                            anchors.rightMargin: 9
                            anchors.top: parent.top
                            anchors.topMargin: 8
                            color: Qt.alpha(root.onAccentColour, 0.62)
                            font: Tokens.font.label.small
                            text: root.worldTimes[parent.modelData]?.[1] ?? ""
                        }
                    }
                }
            }
        }
        Column {
            spacing: 12
            width: 122
            x: 1770
            y: 32

            MetricCard {
                icon: "memory"
                label: "CPU"
                progress: Cpu.percentage
                valueText: root.formatPercent(Cpu.percentage)
            }
            MetricCard {
                icon: "memory_alt"
                label: "RAM"
                progress: Memory.percentage
                valueText: root.formatPercent(Memory.percentage)
            }
            MetricCard {
                icon: "hard_disk"
                label: qsTr("Ổ đĩa")
                progress: Storage.primaryDisk?.perc ?? Storage.percentage
                valueText: root.formatPercent(Storage.primaryDisk?.perc ?? Storage.percentage)
            }
            MetricCard {
                icon: Weather.icon
                label: Weather.city || qsTr("Thời tiết")
                progress: 0
                showProgress: false
                valueText: Weather.temp
            }
        }
        HomeCard {
            id: profileCard

            baseColour: root.cardColourHigh
            height: 218
            width: 286
            x: 1462
            y: 310

            StyledClippingRect {
                id: avatar

                anchors.left: parent.left
                anchors.leftMargin: 18
                anchors.top: parent.top
                anchors.topMargin: 18
                color: root.accentColour
                height: 64
                radius: width / 2
                width: 64

                MaterialIcon {
                    anchors.centerIn: parent
                    color: root.onAccentColour
                    fontStyle: Tokens.font.icon.large
                    text: "person"
                }
                CachingImage {
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    path: `${Paths.home}/.face`
                }
            }
            Column {
                anchors.left: avatar.right
                anchors.leftMargin: 13
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: avatar.verticalCenter
                spacing: 4

                StyledText {
                    color: root.textColour
                    elide: Text.ElideRight
                    font: Tokens.font.title.small
                    text: `${SysInfo.user}@${SysInfo.hostname}`
                    width: parent.width
                }
                StyledText {
                    color: root.mutedColour
                    elide: Text.ElideRight
                    font: Tokens.font.label.small
                    text: qsTr("Hoạt động %1").arg(SysInfo.uptime)
                    width: parent.width
                }
            }
            Row {
                anchors.left: parent.left
                anchors.leftMargin: 18
                anchors.top: avatar.bottom
                anchors.topMargin: 15
                spacing: 6

                MaterialIcon {
                    color: root.mutedColour
                    fontStyle: Tokens.font.icon.small
                    text: Weather.icon
                }
                StyledText {
                    color: root.mutedColour
                    elide: Text.ElideRight
                    font: Tokens.font.body.small
                    text: Weather.description
                    width: 218
                }
            }
            Row {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.margins: 16
                anchors.right: parent.right
                spacing: 9

                Rectangle {
                    color: root.onAccentColour
                    height: 43
                    radius: height / 2
                    width: 126

                    Row {
                        anchors.centerIn: parent
                        spacing: 7

                        MaterialIcon {
                            color: root.accentColour
                            fontStyle: Tokens.font.icon.small
                            text: "lock"
                        }
                        StyledText {
                            color: root.accentColour
                            font: Tokens.font.label.medium
                            text: qsTr("Khóa máy")
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: Quickshell.execDetached(["caelestia", "shell", "lock", "lock"])
                    }
                }
                HomeAction {
                    icon: "settings"

                    onClicked: WindowFactory.create(root.screen)
                }
                HomeAction {
                    icon: "power_settings_new"

                    onClicked: {
                        if (root.screenState)
                            root.screenState.session = !root.screenState.session;
                    }
                }
            }
        }
        HomeCard {
            id: calendarCard

            baseColour: root.cardColour
            clip: true
            height: 268
            width: 286
            x: 1462
            y: 552

            Loader {
                active: root.screenState !== null
                anchors.fill: parent

                sourceComponent: DashboardDash.Calendar {
                    screenState: root.screenState
                }
            }
        }
    }

    component HomeAction: Rectangle {
        id: action

        property bool emphasized: false
        property string icon

        signal clicked

        color: emphasized ? root.onAccentColour : Qt.alpha(root.accentColour, 0.84)
        implicitHeight: implicitWidth
        implicitWidth: emphasized ? 44 : 42
        opacity: enabled ? 1 : 0.38
        radius: width / 2

        MaterialIcon {
            anchors.centerIn: parent
            color: action.emphasized ? root.accentColour : root.onAccentColour
            fill: 1
            fontStyle: action.emphasized ? Tokens.font.icon.medium : Tokens.font.icon.small
            text: action.icon
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            enabled: action.enabled

            onClicked: action.clicked()
        }
    }
    component HomeCard: Rectangle {
        property color baseColour: root.cardColour

        border.color: Qt.alpha(root.outlineColour, 0.3)
        border.width: 1
        color: Qt.alpha(baseColour, root.cardOpacity)
        radius: 28

        Behavior on border.color {
            CAnim {}
        }
        Behavior on color {
            CAnim {}
        }
    }
    component MetricCard: HomeCard {
        id: metric

        required property string icon
        required property string label
        required property real progress
        property bool showProgress: true
        required property string valueText

        baseColour: root.cardColourHigh
        height: 112
        radius: 27
        width: 122

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            color: Colours.palette.m3primary
            height: 5
            opacity: 0.72
            radius: 3
            visible: metric.showProgress
            width: parent.width * Math.max(0, Math.min(1, metric.progress))

            Behavior on width {
                Anim {}
            }
        }
        MaterialIcon {
            anchors.right: parent.right
            anchors.rightMargin: 15
            anchors.top: parent.top
            anchors.topMargin: 14
            color: Colours.palette.m3primary
            fill: 1
            fontStyle: Tokens.font.icon.medium
            text: metric.icon
        }
        StyledText {
            anchors.bottom: labelText.top
            anchors.bottomMargin: 1
            anchors.left: parent.left
            anchors.leftMargin: 15
            color: root.textColour
            font: Tokens.font.title.builders.large.weight(Font.Bold).build()
            text: metric.valueText
        }
        StyledText {
            id: labelText

            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            anchors.left: parent.left
            anchors.leftMargin: 15
            anchors.right: parent.right
            anchors.rightMargin: 10
            color: root.mutedColour
            elide: Text.ElideRight
            font: Tokens.font.label.small
            text: metric.label
        }
    }
}
