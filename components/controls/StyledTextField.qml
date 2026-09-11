pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Caelestia.Config
import qs.components
import qs.services

TextFieldBase {
    id: root

    enum TextFieldType {
        Outlined,
        Filled
    }

    readonly property int clampedRadius: Math.min(horizontalPadding, Math.min(width, height) / 2, radius)
    readonly property string effectiveSupportingText: isError && errorText ? errorText : supportingText
    property bool emptyIsValid: true
    property string errorText
    readonly property int filledOffset: type === StyledTextField.Filled ? Tokens.spacing.small : 0
    readonly property int horizontalPadding: Tokens.padding.large
    property bool isError
    property string leadingIcon
    readonly property int leadingOffset: leadingIcon ? leadingIconLoader.width + leadingIconLoader.anchors.leftMargin : 0
    property int radius: Tokens.rounding.small
    readonly property real smallFontScale: smallFontSize / font.pointSize
    property int smallFontSize: Tokens.font.label.small.pointSize
    property string supportingText
    readonly property int supportingTextOffset: effectiveSupportingText ? supportingTextLoader.height + Tokens.spacing.extraSmall : 0
    property string trailingIcon
    readonly property int trailingOffset: trailingIcon ? trailingIconLoader.width + trailingIconLoader.anchors.rightMargin : 0
    property int type: StyledTextField.Outlined
    readonly property bool valid: validateText(text)
    property var validate // RegExp or function

    function validateText(value: string): bool {
        if (!validate || (!value && emptyIsValid))
            return true;
        if (validate instanceof RegExp)
            return validate.test(value);
        return !!validate(value); // qmllint disable use-proper-function
    }

    bottomPadding: Tokens.padding.large + supportingTextOffset - filledOffset
    leftPadding: horizontalPadding + leadingOffset
    rightPadding: horizontalPadding + trailingOffset
    topPadding: Tokens.padding.large + filledOffset

    background: Loader {
        anchors.bottomMargin: root.supportingTextOffset
        anchors.fill: parent
        sourceComponent: root.type === StyledTextField.Filled ? filledComp : outlineComp

        StateLayer {
            id: stateLayer

            cursorShape: Qt.IBeamCursor
            disabled: root.activeFocus
            manualPressOverride: tapHandler.pressed
            radius: root.type === StyledTextField.Outlined ? root.clampedRadius : 0
            topLeftRadius: root.clampedRadius
            topRightRadius: root.clampedRadius

            onClicked: root.focus = true
        }
    }

    onEditingFinished: {
        if (!valid)
            isError = true;
    }
    onPressed: {
        if (!stateLayer.disabled)
            stateLayer.press(stateLayer.mouseX, stateLayer.mouseY);
    }
    onTextEdited: {
        if (isError)
            isError = false;
    }

    Item {
        id: contentWrapper

        anchors.bottomMargin: root.supportingTextOffset
        anchors.fill: parent

        StyledText {
            id: placeholder

            anchors.left: parent.left
            anchors.leftMargin: root.leftPadding
            anchors.topMargin: Tokens.padding.extraSmall
            anchors.verticalCenter: parent.verticalCenter
            color: root.isError ? Colours.palette.m3error : (root.activeFocus ? Colours.palette.m3primary : root.text ? Colours.palette.m3outline : root.placeholderTextColor)
            font.family: root.font.family
            font.pointSize: root.font.pointSize
            font.variableAxes: root.font.variableAxes
            font.weight: root.font.weight
            renderType: Text.QtRendering
            text: root.placeholderText

            states: [
                State {
                    name: "smallOutlined"
                    when: root.type === StyledTextField.Outlined && (root.activeFocus || root.text)

                    PropertyChanges {
                        placeholder.anchors.leftMargin: -(1 - root.smallFontScale) * placeholder.width / 2 + root.horizontalPadding + -root.Tokens.spacing.extraSmall
                        placeholder.scale: root.smallFontScale
                    }
                    AnchorChanges {
                        anchors.verticalCenter: contentWrapper.top
                        target: placeholder
                    }
                },
                State {
                    name: "smallFilled"
                    when: root.type === StyledTextField.Filled && (root.activeFocus || root.text)

                    PropertyChanges {
                        placeholder.anchors.leftMargin: -(1 - root.smallFontScale) * placeholder.width / 2 + root.horizontalPadding + root.leadingOffset
                        placeholder.scale: root.smallFontScale
                    }
                    AnchorChanges {
                        anchors.top: contentWrapper.top
                        anchors.verticalCenter: undefined
                        target: placeholder
                    }
                }
            ]
            transitions: Transition {
                Anim {
                    properties: "scale,leftMargin"
                    type: Anim.DefaultEffects
                }
                AnchorAnim {
                    duration: Tokens.anim.durations.expressiveDefaultEffects
                    easing: Tokens.anim.expressiveDefaultEffects
                }
            }
        }
        Loader {
            id: leadingIconLoader

            active: root.leadingIcon
            anchors.left: parent.left
            anchors.leftMargin: Tokens.padding.medium
            anchors.verticalCenter: parent.verticalCenter

            sourceComponent: MaterialIcon {
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.builders.medium.scale(0.9).build()
                text: root.leadingIcon
            }
        }
        Loader {
            id: trailingIconLoader

            active: root.trailingIcon
            anchors.right: parent.right
            anchors.rightMargin: Tokens.padding.medium
            anchors.verticalCenter: parent.verticalCenter

            sourceComponent: MaterialIcon {
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.builders.medium.scale(0.9).build()
                text: root.trailingIcon
            }
        }
    }
    Loader {
        id: supportingTextLoader

        active: root.effectiveSupportingText
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: root.horizontalPadding

        sourceComponent: StyledText {
            color: root.isError ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.small
            text: root.effectiveSupportingText
        }
    }
    TapHandler {
        id: tapHandler
    }
    Component {
        id: outlineComp

        Shape {
            id: bg

            asynchronous: true
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                id: path

                readonly property real inset: strokeWidth / 2
                readonly property real outlineGap: placeholder.width * root.smallFontScale + root.Tokens.spacing.extraSmall * 2
                property real outlineGapScale: root.activeFocus || root.text ? 1 : 0

                capStyle: ShapePath.RoundCap
                fillColor: "transparent"
                startX: path.inset + root.horizontalPadding - root.clampedRadius + path.outlineGap * (1 - path.outlineGapScale) / 2 + path.outlineGap * path.outlineGapScale
                strokeColor: root.isError ? Colours.palette.m3error : (root.activeFocus ? Colours.palette.m3primary : Colours.palette.m3outline)
                strokeWidth: root.activeFocus ? 2 : 1

                Behavior on outlineGapScale {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
                Behavior on strokeColor {
                    CAnim {}
                }
                Behavior on strokeWidth {
                    Anim {}
                }

                PathLine {
                    x: bg.width - path.inset - root.clampedRadius
                }
                PathArc {
                    radiusX: root.clampedRadius
                    radiusY: root.clampedRadius
                    x: bg.width - path.inset
                    y: path.inset + root.clampedRadius
                }
                PathLine {
                    x: bg.width - path.inset
                    y: bg.height - path.inset - root.clampedRadius
                }
                PathArc {
                    radiusX: root.clampedRadius
                    radiusY: root.clampedRadius
                    x: bg.width - path.inset - root.clampedRadius
                    y: bg.height - path.inset
                }
                PathLine {
                    x: path.inset + root.clampedRadius
                    y: bg.height - path.inset
                }
                PathArc {
                    radiusX: root.clampedRadius
                    radiusY: root.clampedRadius
                    x: path.inset
                    y: bg.height - path.inset - root.clampedRadius
                }
                PathLine {
                    x: path.inset
                    y: path.inset + root.clampedRadius
                }
                PathArc {
                    radiusX: root.clampedRadius
                    radiusY: root.clampedRadius
                    x: path.inset + root.clampedRadius
                    y: path.inset
                }
                PathLine {
                    x: path.inset + root.horizontalPadding - root.clampedRadius + path.outlineGap * (1 - path.outlineGapScale) / 2
                }
            }
        }
    }
    Component {
        id: filledComp

        StyledRect {
            color: root.activeFocus ? Colours.tPalette.m3surfaceContainerHighest : Colours.tPalette.m3surfaceContainerHigh
            topLeftRadius: root.clampedRadius
            topRightRadius: root.clampedRadius

            StyledRect {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                color: root.isError ? Colours.palette.m3error : (root.activeFocus ? Colours.palette.m3primary : Colours.palette.m3outline)
                implicitHeight: root.activeFocus ? 2 : 1

                Behavior on implicitHeight {
                    Anim {}
                }
            }
        }
    }
}
