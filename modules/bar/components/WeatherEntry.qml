import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    function formattedTemperature(): string {
        const value = Weather.cc?.tempC;
        if (value === undefined)
            return "--°";
        const converted = Config.bar.weather.useUSCS ? value * 9 / 5 + 32 : value;
        return `${Math.round(converted)}°`;
    }

    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: Config.bar.weather.enable ? layout.implicitHeight + Tokens.padding.small * 2 : 0

    visible: implicitHeight > 0
    color: Config.bar.showBackground ? Colours.tPalette.m3surfaceContainer : "transparent"
    radius: Tokens.rounding.full

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const state = ShellState.forActive();
            state.dashboard = true;
        }
    }

    ColumnLayout {
        id: layout

        anchors.centerIn: parent
        spacing: 0

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Weather.icon
            font: Tokens.font.icon.small
            color: Colours.palette.m3tertiary
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: root.formattedTemperature()
            font: Tokens.font.label.small
            color: Colours.palette.m3onSurfaceVariant
        }
    }

    Component.onCompleted: Weather.reload()
}
