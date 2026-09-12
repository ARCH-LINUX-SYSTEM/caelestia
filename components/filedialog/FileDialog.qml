pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.services

LazyLoader {
    id: loader

    property list<string> cwd: ["Home"]
    property string filterLabel: qsTr("Tất cả tệp")
    property list<string> filters: ["*"]
    property string title: qsTr("Chọn tệp")
    property ShellScreen targetScreen
    property var parentWindow

    signal accepted(path: string)
    signal rejected

    function open(): void {
        activeAsync = true;
    }

    function close(): void {
        rejected();
    }

    onAccepted: activeAsync = false
    onRejected: activeAsync = false

    FloatingWindow {
        id: root

        property list<string> cwd: loader.cwd
        property string filterLabel: loader.filterLabel
        property list<string> filters: loader.filters

        readonly property bool selectionValid: {
            const file = folderContents.currentItem?.modelData;
            return (file && !file.isDir && (filters.includes("*") || filters.includes(file.suffix.toLowerCase()))) ?? false;
        }

        function accepted(path: string): void {
            loader.accepted(path);
        }

        function rejected(): void {
            loader.rejected();
        }

        function displayName(name: string): string {
            const names = {
                "Home": qsTr("Trang chủ"),
                "Downloads": qsTr("Tải xuống"),
                "Desktop": qsTr("Màn hình nền"),
                "Documents": qsTr("Tài liệu"),
                "Music": qsTr("Nhạc"),
                "Pictures": qsTr("Hình ảnh"),
                "Public": qsTr("Công khai"),
                "Templates": qsTr("Mẫu"),
                "Videos": qsTr("Video")
            };
            return names[name] ?? name;
        }

        screen: loader.targetScreen ?? ShellState.forActive()?.modelData ?? Quickshell.screens[0]
        parentWindow: loader.parentWindow

        implicitWidth: 1000
        implicitHeight: 600
        minimumSize.width: 400
        minimumSize.height: 300
        color: Colours.tPalette.m3surface
        surfaceFormat.opaque: false
        title: loader.title

        onVisibleChanged: {
            if (!visible)
                rejected();
        }

        RowLayout {
            anchors.fill: parent

            spacing: 0

            Sidebar {
                Layout.fillHeight: true
                dialog: root
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true

                spacing: 0

                HeaderBar {
                    Layout.fillWidth: true
                    dialog: root
                }

                FolderContents {
                    id: folderContents

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    dialog: root
                }

                DialogButtons {
                    Layout.fillWidth: true
                    dialog: root
                    folder: folderContents
                }
            }
        }

        Behavior on color {
            CAnim {}
        }
    }
}
