import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Caelestia
import Caelestia.Config
import qs.components
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    // Plugin support is not wired up yet; always 0 for now
    readonly property int pluginCount: 0

    property string quickshellVersion
    property string cliVersion

    title: qsTr("Giới thiệu")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // e.g. "Quickshell 0.3.0 (revision ...)"
        Process {
            running: true
            command: ["quickshell", "--version"]
            stdout: StdioCollector {
                onStreamFinished: root.quickshellVersion = text.trim().split(" ")[1] ?? ""
            }
        }

        // Parsed from the caelestia CLI's package listing; the sh wrapper avoids a
        // warning when the (optional) CLI isn't installed
        Process {
            running: true
            command: ["sh", "-c", "caelestia --version 2>/dev/null"]
            stdout: StdioCollector {
                onStreamFinished: {
                    const m = text.match(/caelestia-cli\S*\s+(\d+(?:\.\d+)*)/);
                    root.cliVersion = m ? m[1] : "";
                }
            }
        }

        // Hero
        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: hero.implicitHeight + Tokens.padding.extraLarge * 2

            ColumnLayout {
                id: hero

                anchors.centerIn: parent
                width: parent.width - Tokens.padding.largeIncreased * 2
                spacing: Tokens.spacing.small

                AnimatedLogo {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: implicitWidth
                    Layout.preferredHeight: implicitHeight
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Tokens.spacing.small
                    text: "Caelestia"
                    font: Tokens.font.headline.builders.large.width(110).build()
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: CUtils.version ? `v${CUtils.version}` : "…"
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.medium
                }
            }
        }

        SectionHeader {
            text: qsTr("Hồ sơ")
        }

        TextFieldRow {
            first: true
            label: qsTr("Thư mục ảnh đại diện")
            subtext: qsTr("Để trống để tiếp tục dùng ~/.face của Caelestia")
            value: GlobalConfig.profile.avatarPath
            placeholder: "~/Pictures/Avatars"
            leadingIcon: "folder"
            onCommitted: value => GlobalConfig.profile.avatarPath = value.trim()
        }

        TextFieldRow {
            label: qsTr("Ảnh đại diện")
            subtext: qsTr("Đường dẫn đầy đủ hoặc tên tệp nằm trong thư mục phía trên")
            value: GlobalConfig.profile.avatarPicture
            placeholder: "avatar.png"
            leadingIcon: "account_circle"
            onCommitted: value => GlobalConfig.profile.avatarPicture = value.trim()
        }

        TextFieldRow {
            last: true
            label: qsTr("Mô tả hồ sơ")
            subtext: qsTr("Hỗ trợ ::distro::, ::uptime:: hoặc văn bản tùy ý")
            value: GlobalConfig.profile.descriptionText
            placeholder: "::distro::"
            leadingIcon: "badge"
            onCommitted: value => GlobalConfig.profile.descriptionText = value.trim() || "::distro::"
        }

        // System
        SectionHeader {
            text: qsTr("Hệ thống")
        }

        InfoRow {
            first: true
            label: qsTr("Tên máy")
            value: SysInfo.hostname
        }

        InfoRow {
            label: qsTr("Thiết bị")
            value: SysInfo.device
        }

        InfoRow {
            label: qsTr("Bản phân phối")
            value: SysInfo.osPrettyName || SysInfo.osName
        }

        InfoRow {
            label: qsTr("Nhân hệ thống")
            value: SysInfo.kernel
        }

        InfoRow {
            last: true
            label: qsTr("Phần sụn")
            value: SysInfo.firmware
        }

        // Software
        SectionHeader {
            text: qsTr("Phần mềm")
        }

        InfoRow {
            first: true
            label: qsTr("Shell")
            value: CUtils.version || "…"
        }

        InfoRow {
            label: qsTr("CLI")
            value: root.cliVersion || "…"
        }

        InfoRow {
            label: qsTr("Quickshell")
            value: root.quickshellVersion || "…"
        }

        InfoRow {
            last: true
            label: qsTr("Qt")
            value: CUtils.qtVersion || "…"
        }

        // Plugins
        SectionHeader {
            text: qsTr("Tiện ích bổ sung")
        }

        InfoRow {
            first: true
            last: true
            label: qsTr("Tiện ích bổ sung đã nạp")
            value: root.pluginCount.toString()
        }
    }
}
