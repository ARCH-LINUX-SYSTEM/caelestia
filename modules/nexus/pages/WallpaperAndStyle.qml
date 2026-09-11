pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.images
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property list<MenuItem> hwDecoderItems: [
        MenuItem {
            text: qsTr("Tự động")
        },
        MenuItem {
            text: qsTr("Phần mềm")
        },
        MenuItem {
            text: "VAAPI"
        },
        MenuItem {
            text: "VDPAU"
        },
        MenuItem {
            text: "CUDA"
        },
        MenuItem {
            text: "Vulkan"
        },
        MenuItem {
            text: "DRM"
        }
    ]
    readonly property list<string> hwDecoderValues: ["auto", "none", "vaapi", "vdpau", "cuda", "vulkan", "drm"]
    readonly property var hwDecoderIndexMap: ({
            "auto": 0,
            "none": 1,
            "vaapi": 2,
            "vdpau": 3,
            "cuda": 4,
            "vulkan": 5,
            "drm": 6
        })
    readonly property url wallpaperPreview: Wallpapers.getPreviewSource(Wallpapers.current, Wallpapers.itemBusters[Wallpapers.current] || Wallpapers.cacheBuster)

    function hwDecoderToIndex(val: string): int {
        const v = (val ?? "none").toLowerCase();
        return v in hwDecoderIndexMap ? hwDecoderIndexMap[v] : 1; // Default to software (none)
    }

    title: qsTr("Hình nền & kiểu dáng")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.large

        StyledClippingRect {
            id: wallWrapper

            Layout.alignment: Qt.AlignHCenter
            implicitWidth: {
                const screen = root.nState.screen;
                if (!screen || screen.height === 0)
                    return 0;
                return implicitHeight / screen.height * screen.width;
            }
            implicitHeight: {
                const screen = root.nState.screen;
                if (!screen || screen.width === 0)
                    return 0;
                const cWidth = root.cappedWidth;
                return Math.min(Math.round(cWidth * 0.4), cWidth / screen.width * screen.height);
            }

            color: Colours.tPalette.m3surfaceContainer
            radius: Tokens.rounding.large

            Loader {
                anchors.centerIn: parent
                opacity: Config.background.wallpaperEnabled ? 0 : 1
                active: opacity > 0

                sourceComponent: ColumnLayout {
                    spacing: Tokens.spacing.extraSmall

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "hide_image"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.extraLarge
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Hình nền đã tắt")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.large
                    }
                }

                Behavior on opacity {
                    Anim {
                        type: Anim.SlowEffects
                    }
                }
            }

            Item {
                anchors.fill: parent
                opacity: Config.background.wallpaperEnabled ? 1 : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.SlowEffects
                    }
                }

                Loader {
                    id: wallIndicatorLoader

                    anchors.centerIn: parent

                    opacity: 0
                    active: opacity > 0

                    sourceComponent: StyledRect {
                        implicitWidth: wallLoadingIndicator.implicitSize + Tokens.padding.largeIncreased * 2
                        implicitHeight: wallLoadingIndicator.implicitSize + Tokens.padding.largeIncreased * 2

                        color: Colours.palette.m3primaryContainer
                        radius: Tokens.rounding.full

                        LoadingIndicator {
                            id: wallLoadingIndicator

                            anchors.centerIn: parent
                            containsIcon: true
                            implicitSize: Math.min(wallWrapper.implicitWidth, wallWrapper.implicitHeight) * 0.4
                        }
                    }

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }

                Timer {
                    id: wallLoadDebounceTimer

                    interval: 100
                    onTriggered: {
                        if (wallImg.status !== Image.Ready)
                            wallIndicatorLoader.opacity = 1;
                    }
                }

                FadeImage {
                    id: wallImg

                    anchors.fill: parent
                    source: root.wallpaperPreview
                    preventInit: wallIndicatorLoader.opacity > 0
                    fadeOutAnim: Anim.DefaultEffects
                    fadeInAnim: Anim.SlowEffects

                    onSourceChanged: wallLoadDebounceTimer.restart()

                    onStatusChanged: {
                        if (status === Image.Ready) {
                            wallLoadDebounceTimer.stop();
                            wallIndicatorLoader.opacity = 0;
                        }
                    }
                }
            }
        }

        ButtonRow {
            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.spacing.small

            IconTextButton {
                icon: "wallpaper"
                text: qsTr("Hình nền")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                type: IconTextButton.Tonal
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                disabled: !Config.background.wallpaperEnabled
                onClicked: root.nState.openSubPage(1) // Wallpaper page
            }

            IconTextButton {
                icon: "palette"
                text: qsTr("Màu sắc")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                type: IconTextButton.Tonal
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                onClicked: root.nState.openSubPage(3) // Colours page
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall / 2

            SectionHeader {
                first: true
                text: qsTr("Tùy biến")
            }

            NavRow {
                first: true
                icon: "tune"
                label: qsTr("Tinh chỉnh giao diện")
                status: qsTr("Tỷ lệ, độ trong suốt và viền shell")
                onClicked: root.nState.openSubPage(4)
            }

            NavRow {
                icon: "desktop_windows"
                label: qsTr("Desktop & hiệu ứng nền")
                status: qsTr("Đồng hồ, visualiser và thư mục hình nền")
                onClicked: root.nState.openSubPage(5)
            }

            NavRow {
                icon: "wallpaper_slideshow"
                label: qsTr("Trình chọn hình nền nâng cao")
                status: qsTr("Tìm kiếm, đường dẫn nhanh và tự đổi hình nền")
                onClicked: root.nState.openSubPage(6)
            }

            NavRow {
                last: true
                icon: "screenshot_region"
                label: qsTr("Task View & chụp vùng")
                status: qsTr("Bố cục cửa sổ, vùng bám và công cụ chú thích")
                onClicked: root.nState.openSubPage(7)
            }
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: qsTr("Hiển thị hình nền")
            checked: Config.background.wallpaperEnabled
            onToggled: GlobalConfig.background.wallpaperEnabled = checked
        }

        SelectRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true

            label: qsTr("Bộ giải mã video phần cứng")
            menuOnTop: true
            menuItems: root.hwDecoderItems
            active: root.hwDecoderItems[root.hwDecoderToIndex(WallpaperPauser.hwDecoder)]
            onSelected: item => WallpaperPauser.hwDecoder = root.hwDecoderValues[root.hwDecoderItems.indexOf(item)]
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true

            text: qsTr("Tạm dừng hình nền động khi dùng pin")
            checked: WallpaperPauser.pauseOnBattery
            onToggled: WallpaperPauser.pauseOnBattery = checked
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true

            text: qsTr("Tạm dừng hình nền động khi bị cửa sổ che")
            checked: WallpaperPauser.pauseOnWindowOverlap
            onToggled: WallpaperPauser.pauseOnWindowOverlap = checked
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true

            text: qsTr("Độ trong suốt")
            subtext: qsTr("Nền %1, lớp %2").arg(Colours.transparency.base).arg(Colours.transparency.layers)
            checked: Colours.transparency.enabled
            onToggled: GlobalConfig.appearance.transparency.enabled = checked
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true

            last: true
            text: qsTr("Giao diện tối")
            checked: !Colours.light
            onToggled: Colours.setMode(checked ? "dark" : "light")
        }
    }
}
