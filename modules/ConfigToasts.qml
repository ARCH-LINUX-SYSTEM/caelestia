import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config

Scope {
    Connections {
        function onLoaded(): void {
            if (GlobalConfig.utilities.toasts.configLoaded)
                Toaster.toast(qsTr("Đã tải cấu hình"), qsTr("Đã tải cấu hình thành công!"), "rule_settings");
        }

        function onLoadFailed(error: string, screen: string): void {
            Toaster.toast(qsTr("Không thể phân tích cấu hình%1").arg(screen ? " cho " + screen : ""), error, "settings_alert", Toast.Warning);
        }

        function onSaveFailed(error: string, screen: string): void {
            Toaster.toast(qsTr("Không thể lưu cấu hình%1").arg(screen ? " cho " + screen : ""), error, "settings_alert", Toast.Error);
        }

        function onUnknownOption(key: string, screen: string): void {
            Toaster.toast(qsTr("Tùy chọn không xác định trong cấu hình%1").arg(screen ? " " + screen : ""), key, "question_mark", Toast.Warning);
        }

        target: GlobalConfig
    }

    Connections {
        function onLoadFailed(error: string, screen: string): void {
            Toaster.toast(qsTr("Không thể phân tích cấu hình token%1").arg(screen ? " cho " + screen : ""), error, "settings_alert", Toast.Warning);
        }

        function onUnknownOption(key: string, screen: string): void {
            Toaster.toast(qsTr("Tùy chọn không xác định trong cấu hình token%1").arg(screen ? " " + screen : ""), key, "question_mark", Toast.Warning);
        }

        target: TokenConfig
    }
}
