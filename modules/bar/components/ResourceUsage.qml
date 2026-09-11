pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.Services
import qs.components

StyledRect {
    id: root

    function percent(value: real): int {
        return Math.round(Math.max(0, Math.min(1, value)) * 100);
    }

    readonly property list<var> metrics: [
        {
            enabled: Config.bar.resources.alwaysShowCpu,
            icon: "memory",
            value: root.percent(Cpu.percentage),
            suffix: "%",
            warning: Config.bar.resources.cpuWarningThreshold
        },
        {
            enabled: Config.bar.resources.alwaysShowCpuTemp,
            icon: "thermostat",
            value: Math.round(Cpu.temperature),
            suffix: "°",
            warning: Config.bar.resources.cpuWarningThreshold
        },
        {
            enabled: Config.bar.resources.alwaysShowRam,
            icon: "memory_alt",
            value: root.percent(Memory.percentage),
            suffix: "%",
            warning: Config.bar.resources.memoryWarningThreshold
        },
        {
            enabled: Config.bar.resources.alwaysShowDisk,
            icon: "hard_disk",
            value: root.percent(Storage.percentage),
            suffix: "%",
            warning: 101
        },
        {
            enabled: Config.bar.resources.alwaysShowSwap,
            icon: "swap_horiz",
            value: -1,
            suffix: "",
            warning: Config.bar.resources.swapWarningThreshold
        }
    ]

    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: layout.implicitHeight + (shown.count > 0 ? Tokens.padding.small * 2 : 0)

    visible: shown.count > 0
    color: Config.bar.showBackground ? Colours.tPalette.m3surfaceContainer : "transparent"
    radius: Tokens.rounding.full

    ServiceRef {
        service: Cpu
    }

    ServiceRef {
        service: Memory
    }

    ServiceRef {
        service: Storage
    }

    ColumnLayout {
        id: layout

        anchors.centerIn: parent
        spacing: Tokens.spacing.extraSmall

        Repeater {
            id: shown

            model: ScriptModel {
                values: root.metrics.filter(metric => metric.enabled)
            }

            RowLayout {
                id: metric

                required property var modelData
                spacing: 0

                MaterialIcon {
                    text: metric.modelData.icon
                    fontStyle: Tokens.font.icon.small
                    color: metric.modelData.value >= metric.modelData.warning ? Colours.palette.m3error : Colours.palette.m3secondary
                }

                StyledText {
                    visible: Config.bar.resources.showValue
                    text: metric.modelData.value < 0 ? "--" : `${metric.modelData.value}${metric.modelData.suffix}`
                    font: Tokens.font.label.small
                    color: metric.modelData.value >= metric.modelData.warning ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                }
            }
        }
    }
}
