pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property var entryMetadata: ({
            "logo": {
                label: qsTr("Logo"),
                icon: "desktop_windows"
            },
            "workspaces": {
                label: qsTr("Không gian làm việc"),
                icon: "workspaces"
            },
            "spacer": {
                label: qsTr("Khoảng trống"),
                icon: "unfold_more"
            },
            "activeWindow": {
                label: qsTr("Cửa sổ đang hoạt động"),
                icon: "web_asset"
            },
            "tray": {
                label: qsTr("Khay hệ thống"),
                icon: "widgets"
            },
            "clock": {
                label: qsTr("Đồng hồ"),
                icon: "schedule"
            },
            "resources": {
                label: qsTr("Tài nguyên"),
                icon: "memory"
            },
            "weather": {
                label: qsTr("Thời tiết"),
                icon: "partly_cloudy_day"
            },
            "statusIcons": {
                label: qsTr("Biểu tượng trạng thái"),
                icon: "signal_cellular_alt"
            },
            "power": {
                label: qsTr("Nguồn"),
                icon: "power_settings_new"
            }
        })

    function copyEntries(): var {
        return [...GlobalConfig.bar.entries].map(entry => Object.assign({}, entry));
    }

    function setEntryEnabled(index: int, enabled: bool): void {
        const entries = copyEntries();
        if (index < 0 || index >= entries.length)
            return;
        entries[index].enabled = enabled;
        GlobalConfig.bar.entries = entries;
    }

    function moveEntry(index: int, offset: int): void {
        const entries = copyEntries();
        const target = index + offset;
        if (index < 0 || index >= entries.length || target < 0 || target >= entries.length)
            return;
        const current = entries[index];
        entries[index] = entries[target];
        entries[target] = current;
        GlobalConfig.bar.entries = entries;
    }

    function spacerOrdinal(index: int): int {
        let ordinal = 0;
        for (let i = 0; i <= index; i++) {
            if (GlobalConfig.bar.entries[i]?.id === "spacer")
                ordinal++;
        }
        return ordinal;
    }

    function entryLabel(entry: var, index: int): string {
        const metadata = entryMetadata[entry.id];
        const base = metadata?.label ?? entry.id ?? qsTr("Thành phần không rõ");
        return entry.id === "spacer" ? qsTr("%1 %2").arg(base).arg(spacerOrdinal(index)) : base;
    }

    function entryIcon(entry: var): string {
        return entryMetadata[entry.id]?.icon ?? "extension";
    }

    function exactScreenExclusion(name: string): bool {
        return GlobalConfig.bar.excludedScreens.includes(name);
    }

    function patternScreenExclusion(name: string): bool {
        return !exactScreenExclusion(name) && Strings.testRegexList(GlobalConfig.bar.excludedScreens, name);
    }

    function setScreenExcluded(name: string, excluded: bool): void {
        const current = [...GlobalConfig.bar.excludedScreens];
        if (excluded) {
            if (!current.includes(name))
                current.push(name);
            GlobalConfig.bar.excludedScreens = current;
        } else {
            GlobalConfig.bar.excludedScreens = current.filter(entry => entry !== name);
        }
    }

    title: qsTr("Bố cục thanh tác vụ")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Thứ tự thành phần")
        }

        Repeater {
            id: entryList

            model: GlobalConfig.bar.entries

            ConnectedRect {
                id: entryRow

                required property var modelData
                required property int index

                Layout.fillWidth: true
                first: index === 0
                last: index === entryList.count - 1
                implicitHeight: entryLayout.implicitHeight + entryLayout.anchors.margins * 2

                RowLayout {
                    id: entryLayout

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.largeIncreased
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        text: root.entryIcon(entryRow.modelData)
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.medium
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: root.entryLabel(entryRow.modelData, entryRow.index)
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: entryRow.modelData.id ?? ""
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                        }
                    }

                    StyledSwitch {
                        checked: entryRow.modelData.enabled ?? true
                        onToggled: root.setEntryEnabled(entryRow.index, checked)
                    }

                    IconButton {
                        icon: "arrow_upward"
                        type: IconButton.Tonal
                        disabled: entryRow.index === 0
                        onClicked: root.moveEntry(entryRow.index, -1)
                    }

                    IconButton {
                        icon: "arrow_downward"
                        type: IconButton.Tonal
                        disabled: entryRow.index === entryList.count - 1
                        onClicked: root.moveEntry(entryRow.index, 1)
                    }
                }
            }
        }

        SectionHeader {
            text: qsTr("Màn hình")
        }

        Repeater {
            id: screenList

            model: Quickshell.screens

            ToggleRow {
                required property ShellScreen modelData
                required property int index
                readonly property bool excludedExactly: root.exactScreenExclusion(modelData.name)
                readonly property bool excludedByPattern: root.patternScreenExclusion(modelData.name)

                first: index === 0
                last: index === screenList.count - 1
                enabled: !excludedByPattern
                opacity: enabled ? 1 : 0.55
                text: modelData.name
                subtext: excludedByPattern ? qsTr("Đang bị loại bởi biểu thức trong shell.json") : qsTr("Ẩn thanh tác vụ trên màn hình này")
                checked: excludedExactly || excludedByPattern
                onToggled: root.setScreenExcluded(modelData.name, checked)
            }
        }

        ConnectedRect {
            Layout.fillWidth: true
            visible: screenList.count === 0
            first: true
            last: true
            implicitHeight: emptyScreens.implicitHeight + Tokens.padding.extraLarge * 2

            StyledText {
                id: emptyScreens

                anchors.centerIn: parent
                text: qsTr("Chưa phát hiện màn hình")
                color: Colours.palette.m3outline
                font: Tokens.font.body.small
            }
        }
    }
}
