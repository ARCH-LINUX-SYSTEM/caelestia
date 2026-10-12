pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Bar status indicator for running Claude Code sessions. Lives inside the
// StatusIcons group (see StatusIcons.qml) under the popout name "claudeagents".
Item {
    id: root

    property color colour: Colours.palette.m3secondary
    readonly property color iconColour: ClaudeAgents.needsAttention ? Colours.palette.m3error : colour

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    MaterialIcon {
        id: icon

        anchors.centerIn: parent

        text: ClaudeAgents.needsAttention ? "notification_important" : "smart_toy"
        animate: true
        color: root.iconColour
        fill: ClaudeAgents.anyBusy || ClaudeAgents.needsAttention ? 1 : 0

        Behavior on fill {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        SequentialAnimation on opacity {
            running: ClaudeAgents.anyBusy && !ClaudeAgents.needsAttention
            alwaysRunToEnd: true
            loops: Animation.Infinite

            Anim {
                from: 1
                to: 0.35
                duration: Tokens.anim.durations.extraLarge
                easing: Tokens.anim.standardAccel
            }
            Anim {
                from: 0.35
                to: 1
                duration: Tokens.anim.durations.extraLarge
                easing: Tokens.anim.standardDecel
            }
        }
    }

    StyledRect {
        id: badge

        anchors.horizontalCenter: icon.right
        anchors.verticalCenter: icon.top
        anchors.verticalCenterOffset: Tokens.padding.extraSmall

        visible: ClaudeAgents.activeCount > 1 || ClaudeAgents.subagentCount > 0
        implicitWidth: Math.max(implicitHeight, count.implicitWidth + Tokens.padding.extraSmall * 2)
        implicitHeight: count.implicitHeight

        radius: Tokens.rounding.full
        color: ClaudeAgents.needsAttention ? Colours.palette.m3error : Colours.palette.m3primary

        StyledText {
            id: count

            anchors.centerIn: parent

            // Sessions count; when subagents are running show those instead (more useful at a glance)
            text: `${ClaudeAgents.subagentCount > 0 ? ClaudeAgents.subagentCount : ClaudeAgents.activeCount}`
            font: Tokens.font.label.small
            color: ClaudeAgents.needsAttention ? Colours.palette.m3onError : Colours.palette.m3onPrimary
        }
    }
}
