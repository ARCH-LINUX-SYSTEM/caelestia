import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

ColumnLayout {
    spacing: Tokens.spacing.small

    StyledText {
        text: qsTr("Khóa chữ hoa: %1").arg(Hypr.capsLock ? qsTr("Bật") : qsTr("Tắt"))
    }

    StyledText {
        text: qsTr("Khóa số: %1").arg(Hypr.numLock ? qsTr("Bật") : qsTr("Tắt"))
    }
}
