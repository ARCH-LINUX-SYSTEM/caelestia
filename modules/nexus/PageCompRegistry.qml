pragma Singleton

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus
import qs.modules.nexus.common
import qs.modules.nexus.pages
import qs.modules.nexus.pages.apps
import qs.modules.nexus.pages.audio
import qs.modules.nexus.pages.bluetooth
import qs.modules.nexus.pages.network
import qs.modules.nexus.pages.panels
import qs.modules.nexus.pages.services
import qs.modules.nexus.pages.wallandstyle
import qs.modules.nexus.pages.panels.taskbar

QtObject {
    id: root

    readonly property Component appearanceComp: Component {
        StackPage {
            Component {
                WallpaperAndStyle {}
            }
            Component {
                WallpaperSelect {}
            }
            Component {
                WallpaperCategory {}
            }
            Component {
                ColourSelect {}
            }
            Component {
                InterfaceTuning {}
            }
            Component {
                DesktopEffects {}
            }
            Component {
                WallpaperOptions {}
            }
            Component {
                CaptureAndOverview {}
            }
        }
    }

    readonly property Component networkComp: Component {
        StackPage {
            Component {
                NetworkPage {}
            }
            Component {
                EthernetDetailPage {}
            }
            Component {
                AddNetworkPage {}
            }
            Component {
                NetworkDetailPage {}
            }
        }
    }

    readonly property Component bluetoothComp: Component {
        StackPage {
            Component {
                BluetoothPage {}
            }
            Component {
                BtDeviceInfo {}
            }
            Component {
                BluetoothPairing {}
            }
        }
    }

    readonly property Component audioComp: Component {
        StackPage {
            Component {
                AudioPage {}
            }
            Component {
                AppVolumes {}
            }
        }
    }

    readonly property Component hyprlandComp: Component {
        StackPage {
            Component {
                HyprlandPage {}
            }
        }
    }

    readonly property Component updatesComp: Component {
        PlaceholderComp {}
    }

    readonly property Component behaviourComp: Component {
        StackPage {
            Component {
                ShellBehaviour {}
            }
        }
    }

    readonly property Component panelsComp: Component {
        StackPage {
            Component {
                PanelsPage {}
            }
            Component {
                DashboardPanel {}
            }
            Component {
                TaskbarPanel {}
            }
            Component {
                LauncherPanel {}
            }
            Component {
                SidebarPanel {}
            }

            // Taskbar component sub-pages
            Component {
                BarWorkspaces {}
            }
            Component {
                BarActiveWindow {}
            }
            Component {
                BarTray {}
            }
            Component {
                BarStatusIcons {}
            }
            Component {
                BarClock {}
            }
            Component {
                BarLayout {}
            }
            Component {
                QuickToggles {}
            }
            Component {
                BarExtras {}
            }
        }
    }

    readonly property Component appsComp: Component {
        StackPage {
            Component {
                AppsPage {}
            }
            Component {
                AllApps {}
            }
            Component {
                AppInfo {}
            }
        }
    }

    readonly property Component servicesComp: Component {
        StackPage {
            Component {
                ServicesPage {}
            }
            Component {
                NotificationsPage {}
            }
        }
    }

    readonly property Component regionComp: Component {
        StackPage {
            Component {
                LanguageAndRegion {}
            }
        }
    }

    readonly property Component aboutComp: Component {
        StackPage {
            Component {
                AboutPage {}
            }
        }
    }

    readonly property Component placeholderComp: Component {
        PlaceholderComp {}
    }

    readonly property var pageCompsById: ({
            "appearance": appearanceComp,
            "network": networkComp,
            "bluetooth": bluetoothComp,
            "audio": audioComp,
            "updates": updatesComp,
            "hyprland": hyprlandComp,
            "behaviour": behaviourComp,
            "addons": placeholderComp,
            "panels": panelsComp,
            "apps": appsComp,
            "services": servicesComp,
            "region": regionComp,
            "about": aboutComp
        })

    function componentFor(pageId: string): Component {
        return pageCompsById[pageId] ?? placeholderComp;
    }

    function validateRegistry(): void {
        const metadataIds = new Set();
        for (const page of PageRegistry.pages) {
            const pageId = page.id ?? "";
            if (!pageId) {
                console.warn("PageCompRegistry: page metadata is missing a stable id");
                continue;
            }
            if (metadataIds.has(pageId))
                console.warn("PageCompRegistry: duplicate page id:", pageId);
            metadataIds.add(pageId);

            if (!pageCompsById[pageId])
                console.warn("PageCompRegistry: no component registered for page id:", pageId);
        }

        for (const pageId of Object.keys(pageCompsById)) {
            if (!metadataIds.has(pageId))
                console.warn("PageCompRegistry: component has no page metadata:", pageId);
        }
    }

    Component.onCompleted: validateRegistry()

    component PlaceholderComp: Item {
        property NexusState nState // To avoid the warning from non-existent property

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Tokens.padding.extraSmall

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "handyman"
                color: Colours.palette.m3outlineVariant
                fontStyle: Tokens.font.icon.extraLarge
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Trang đang được xây dựng")
                color: Colours.palette.m3outlineVariant
                font: Tokens.font.title.large
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Trang này sẽ có trong bản cập nhật sau.")
                color: Colours.palette.m3outlineVariant
                font: Tokens.font.body.large
            }
        }
    }
}
