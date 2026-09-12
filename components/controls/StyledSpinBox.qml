import QtQuick
import QtQuick.Templates
import Caelestia.Config
import qs.components
import qs.services

// Qt 6.10 chưa có DoubleSpinBox. Dùng SpinBox số nguyên với hệ số tỉ lệ
// để giữ nguyên API giá trị thực mà Nexus cần.
SpinBox {
    id: root

    property int cLayer: 1
    readonly property int decimals: realStepSize < 1 ? Math.max(1, Math.ceil(-Math.log10(realStepSize))) : 0
    property real realFrom: 0
    property real realStepSize: 1
    property real realTo: 99
    property real realValue: 0
    property int repeatDecay: 50
    property int repeatRate: 400
    readonly property int valueScale: Math.pow(10, decimals)

    signal realValueModified(value: real)

    function decrease(): void {
        let newValue = Math.max(from, value - stepSize);
        value = newValue;
        valueModified();
    }
    function formattedValue(value: int, locale): string {
        return Number(value / root.valueScale).toLocaleString(locale, "f", root.decimals);
    }
    function increase(): void {
        let newValue = Math.min(to, value + stepSize);
        value = newValue;
        valueModified();
    }

    editable: true
    from: Math.round(realFrom * valueScale)
    implicitHeight: Math.max(up.indicator.implicitHeight, down.indicator.implicitHeight, contentItem.implicitHeight) + topPadding + bottomPadding
    implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
    leftPadding: up.indicator.implicitWidth + Tokens.spacing.extraSmall / 2
    rightPadding: down.indicator.implicitWidth + Tokens.spacing.extraSmall / 2
    spacing: Tokens.spacing.small
    stepSize: Math.max(1, Math.round(realStepSize * valueScale))
    textFromValue: (value, locale) => root.formattedValue(value, locale)
    to: Math.round(realTo * valueScale)
    value: Math.round(realValue * valueScale)
    valueFromText: (text, locale) => Math.round(Number.fromLocaleString(locale, text) * root.valueScale)

    contentItem: TextFieldBase {
        horizontalAlignment: TextField.AlignHCenter
        implicitWidth: 65
        inputMethodHints: Qt.ImhFormattedNumbersOnly
        leftPadding: Tokens.padding.medium
        readOnly: !root.editable
        rightPadding: Tokens.padding.medium
        text: root.formattedValue(root.value, root.locale)

        background: StyledRect {
            color: Colours.layer(Colours.palette.m3surfaceContainerHighest, root.cLayer)
            radius: Tokens.rounding.extraSmall
        }
        validator: DoubleValidator {
            bottom: Math.min(root.realFrom, root.realTo)
            decimals: root.decimals
            locale: root.locale.name
            notation: DoubleValidator.StandardNotation
            top: Math.max(root.realFrom, root.realTo)
        }
    }
    down.indicator: IconButton {
        id: downButton

        bottomRightRadius: pressed ? Tokens.rounding.small : Tokens.rounding.extraSmall
        color: disabled ? disabledColour : Colours.layer(Colours.palette.m3surfaceContainerHighest, root.cLayer)
        disabled: !enabled
        disabledColour: Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.4)
        icon: "remove"
        isRound: true
        label.anchors.horizontalCenterOffset: pressed ? 0 : 2
        padding: Tokens.padding.extraSmall
        topRightRadius: pressed ? Tokens.rounding.small : Tokens.rounding.extraSmall
        type: IconButton.Text

        Behavior on bottomRightRadius {
            Anim {
                type: Anim.DefaultEffects
            }
        }
        Behavior on label.anchors.horizontalCenterOffset {
            Anim {
                type: Anim.DefaultEffects
            }
        }
        Behavior on topRightRadius {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
    up.indicator: IconButton {
        id: upButton

        anchors.right: parent.right
        bottomLeftRadius: pressed ? Tokens.rounding.small : Tokens.rounding.extraSmall
        color: disabled ? disabledColour : Colours.layer(Colours.palette.m3surfaceContainerHighest, root.cLayer)
        disabled: !enabled
        disabledColour: Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.4)
        icon: "add"
        isRound: true
        label.anchors.horizontalCenterOffset: pressed ? 0 : -2
        padding: Tokens.padding.extraSmall
        topLeftRadius: pressed ? Tokens.rounding.small : Tokens.rounding.extraSmall
        type: IconButton.Text

        Behavior on bottomLeftRadius {
            Anim {
                type: Anim.DefaultEffects
            }
        }
        Behavior on label.anchors.horizontalCenterOffset {
            Anim {
                type: Anim.DefaultEffects
            }
        }
        Behavior on topLeftRadius {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    onValueModified: realValueModified(value / valueScale)

    Timer {
        id: timer

        interval: root.repeatRate
        repeat: true
        running: upButton.pressed || downButton.pressed
        triggeredOnStart: true

        onRunningChanged: {
            if (!running)
                interval = root.repeatRate;
        }
        onTriggered: {
            if (upButton.pressed)
                root.increase();
            else if (downButton.pressed)
                root.decrease();
            if (interval > root.repeatDecay)
                interval -= root.repeatDecay;
        }
    }
}
