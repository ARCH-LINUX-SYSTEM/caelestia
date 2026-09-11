pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Dialogs as SystemDialogs
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Caelestia.Components
import Caelestia.Config
import Caelestia.Models
import qs.components
import qs.components.controls
import qs.components.filedialog
import qs.components.images
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    property string wallpaperSearch
    readonly property var filteredWallpapers: {
        const query = GlobalConfig.nexus.showWallpaperSearch ? wallpaperSearch.trim().toLocaleLowerCase() : "";
        if (!query)
            return Wallpapers.allWallpapers;
        return Wallpapers.allWallpapers.filter(wallpaper => {
            return [wallpaper.name, wallpaper.relativePath, wallpaper.parentDir].some(value => String(value ?? "").toLocaleLowerCase().includes(query));
        });
    }

    function closeAfterSelection(): void {
        if (GlobalConfig.nexus.closeAfterWallpaperSelection)
            nState.closeSubPage();
    }

    function preferredBrowsePath(): string {
        const custom = Paths.absolutePath(GlobalConfig.nexus.wallpaperUserPath.trim());
        if (custom)
            return custom;
        return GlobalConfig.nexus.showWallpaperHomePath ? Paths.home : Paths.wallsdir;
    }

    function preferredBrowseCwd(): list<string> {
        const path = preferredBrowsePath();
        if (path === Paths.home)
            return ["Home"];
        if (path.startsWith(Paths.home + "/"))
            return ["Home"].concat(path.slice(Paths.home.length + 1).split("/").filter(part => part));
        return path.split("/");
    }

    function selectWallpaper(path: string): void {
        Wallpapers.setWallpaper(path);
        closeAfterSelection();
    }

    title: qsTr("Hình nền")
    isSubPage: true

    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        implicitHeight: content.implicitHeight
        clip: true

        Item {
            anchors.fill: parent
            visible: GlobalConfig.nexus.showWallpaperBlurBackground
            opacity: 0.22

            FadeImage {
                anchors.fill: parent
                source: Wallpapers.getPreviewSource(Wallpapers.current, Wallpapers.itemBusters[Wallpapers.current] || Wallpapers.cacheBuster)

                layer.enabled: true
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blur: 1
                    blurMax: 64
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            visible: GlobalConfig.nexus.showWallpaperBlurBackground
            color: Colours.tPalette.m3surface
            opacity: 0.72
        }

        ColumnLayout {
            id: content

            width: parent.width
            spacing: Tokens.spacing.small

            ButtonRow {
                Layout.bottomMargin: Tokens.spacing.medium
                Layout.alignment: Qt.AlignHCenter
                spacing: Tokens.spacing.small

                IconTextButton {
                    icon: "photo_library"
                    text: qsTr("Duyệt")
                    font: Tokens.font.body.large
                    isRound: true
                    shapeMorph: true
                    horizontalPadding: Tokens.padding.extraLarge
                    verticalPadding: Tokens.padding.medium
                    onClicked: {
                        if (GlobalConfig.nexus.useSystemFileDialog)
                            systemBrowseDialog.open();
                        else
                            browseDialog.open();
                    }

                    FileDialog {
                        id: browseDialog

                        cwd: root.preferredBrowseCwd()
                        targetScreen: root.nState.screen
                        parentWindow: root.nState.isWindow ? root.QsWindow.window : null
                        title: qsTr("Chọn hình nền")
                        filterLabel: qsTr("Tệp hình nền")
                        filters: Images.validImageExtensions.concat(Wallpapers.validVideoExtensions)
                        onAccepted: path => root.selectWallpaper(path)
                    }
                }

                IconTextButton {
                    icon: "shuffle"
                    text: qsTr("Ngẫu nhiên")
                    font: Tokens.font.body.large
                    isRound: true
                    shapeMorph: true
                    horizontalPadding: Tokens.padding.extraLarge
                    verticalPadding: Tokens.padding.medium
                    type: IconTextButton.Tonal
                    onClicked: {
                        Wallpapers.setRandom();
                        root.closeAfterSelection();
                    }
                }
            }

            SystemDialogs.FileDialog {
                id: systemBrowseDialog

                title: qsTr("Chọn hình nền")
                currentFolder: Wallpapers.localFileUrl(root.preferredBrowsePath())
                nameFilters: [
                    qsTr("Tệp hình nền (%1)").arg(Wallpapers.validWallpaperExtensions.map(extension => "*." + extension).join(" ")),
                    qsTr("Tất cả tệp (*)")
                ]
                onAccepted: root.selectWallpaper(String(selectedFile))
            }

            StyledTextField {
                Layout.fillWidth: true
                visible: GlobalConfig.nexus.showWallpaperSearch
                leadingIcon: "search"
                placeholderText: qsTr("Tìm hình nền hoặc danh mục")
                onTextChanged: root.wallpaperSearch = text
            }

            WallItem {
                imgHeight: Math.round(width * 0.3)
                radius: Tokens.rounding.extraLarge
                source: Quickshell.shellPath("assets/wallpaper.webp")
                text: qsTr("Hình nền nổi bật")
                fillLabel: false
                onClicked: root.selectWallpaper(Quickshell.shellPath("assets/wallpaper.webp"))
            }

            StyledText {
                Layout.topMargin: Tokens.spacing.large
                text: qsTr("Hình nền cục bộ")
                font: Tokens.font.title.small
            }

            GridLayout {
                Layout.fillWidth: true
                visible: root.filteredWallpapers.length > 0

                columns: Config.nexus.wallpapersPerRow
                rowSpacing: Tokens.spacing.medium
                columnSpacing: Tokens.spacing.large

                Repeater {
                    id: localWalls

                    model: {
                        const walls = root.filteredWallpapers;
                        const baseDir = Paths.wallsdir;
                        const categories = {};
                        const list = [];
                        for (const w of walls) {
                            if (w.parentDir !== baseDir) {
                                const category = Wallpapers.getCategoryFor(w);
                                if (category && (!(category in categories) || categories[category].name.localeCompare(w.name) > 0))
                                    categories[category] = w;
                            } else {
                                list.push(w);
                            }
                        }
                        list.push(...Object.values(categories));
                        list.sort((a, b) => ((a.parentDir === baseDir) - (b.parentDir === baseDir)) || a.name.localeCompare(b.name));
                        while (list.length < Config.nexus.wallpapersPerRow)
                            list.push(null);
                        return list;
                    }

                    WallItem {
                        required property FileSystemEntry modelData

                        // Empty placeholders for sizing
                        opacity: modelData ? 1 : 0
                        enabled: modelData

                        source: String(modelData?.path ?? "")
                        text: {
                            if (!modelData)
                                return "";

                            if (modelData.parentDir !== Paths.wallsdir) {
                                const category = Wallpapers.getCategoryFor(modelData);
                                return category.slice(0, 1).toUpperCase() + category.slice(1);
                            }
                            return modelData.name;
                        }
                        onClicked: {
                            if (modelData.parentDir !== Paths.wallsdir) {
                                root.nState.selectedWallpaperCategory = Wallpapers.getCategoryFor(modelData);
                                root.nState.openSubPage(2); // Category page
                            } else {
                                root.selectWallpaper(modelData.path);
                            }
                        }
                    }
                }
            }

            Loader {
                Layout.fillWidth: true

                asynchronous: true
                active: root.filteredWallpapers.length === 0
                visible: active

                sourceComponent: StyledRect {
                    color: Colours.tPalette.m3surfaceContainer
                    radius: Tokens.rounding.extraLarge
                    implicitHeight: noWallsLayout.implicitHeight + Tokens.padding.extraExtraLarge * 2

                    ColumnLayout {
                        id: noWallsLayout

                        anchors.centerIn: parent
                        spacing: Tokens.spacing.extraSmall

                        MaterialIcon {
                            Layout.alignment: Qt.AlignHCenter
                            text: "hide_image"
                            color: Colours.palette.m3outline
                            fontStyle: Tokens.font.icon.extraLarge
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.wallpaperSearch ? qsTr("Không có hình nền khớp tìm kiếm") : qsTr("Không tìm thấy hình nền cục bộ")
                            color: Colours.palette.m3outline
                            font: Tokens.font.title.small
                        }
                    }
                }
            }
        }
    }
}
