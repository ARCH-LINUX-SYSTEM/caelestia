pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

ConnectedRect {
    id: root

    property alias label: label.text
    property string subtext
    property string value
    property string placeholder
    property string leadingIcon
    property bool emptyIsValid: true
    property var validate

    signal committed(value: string)

    function commit(): void {
        if (!field.valid) {
            field.isError = true;
            return;
        }
        if (field.text !== value)
            committed(field.text);
    }

    onValueChanged: {
        if (!field.activeFocus && field.text !== value)
            field.text = value;
    }
    Component.onCompleted: field.text = value

    Layout.fillWidth: true
    implicitHeight: rowLayout.implicitHeight + rowLayout.anchors.margins * 2

    RowLayout {
        id: rowLayout

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.largeIncreased
        spacing: Tokens.spacing.medium

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                id: label

                Layout.fillWidth: true
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.subtext
                text: root.subtext
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }
        }

        StyledTextField {
            id: field

            Layout.preferredWidth: Math.min(320, Math.max(180, root.width * 0.45))
            placeholderText: root.placeholder
            leadingIcon: root.leadingIcon
            emptyIsValid: root.emptyIsValid
            validate: root.validate

            onAccepted: root.commit()
            onEditingFinished: root.commit()
        }
    }
}
