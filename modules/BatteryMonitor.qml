import QtQuick
import Quickshell
import Quickshell.Services.UPower
import Caelestia
import Caelestia.Config
import Caelestia.Services

Scope {
    id: root

    readonly property list<var> warnLevels: [...GlobalConfig.general.battery.warnLevels].sort((a, b) => b.level - a.level)
    readonly property bool shouldAutoHibernate: GlobalConfig.general.battery.autoHibernate && UPower.displayDevice.isLaptopBattery && UPower.onBattery && UPower.displayDevice.percentage * 100 <= GlobalConfig.general.battery.criticalLevel

    function syncAutoHibernate(): void {
        if (!shouldAutoHibernate) {
            hibernateTimer.stop();
            return;
        }
        if (hibernateTimer.running)
            return;

        const delay = Math.max(0, GlobalConfig.general.battery.hibernateDelay);
        Toaster.toast(delay > 0 ? qsTr("Sẽ ngủ đông sau %1 giây").arg(delay) : qsTr("Sắp ngủ đông"), qsTr("Hệ thống sẽ ngủ đông để tránh mất dữ liệu"), "battery_android_alert", Toast.Error);
        hibernateTimer.start();
    }

    onShouldAutoHibernateChanged: syncAutoHibernate()
    Component.onCompleted: syncAutoHibernate()

    Connections {
        function onOnBatteryChanged(): void {
            if (UPower.onBattery) {
                if (GlobalConfig.utilities.toasts.chargingChanged)
                    Toaster.toast(qsTr("Đã rút sạc"), qsTr("Pin đang xả"), "power_off");
            } else {
                if (GlobalConfig.utilities.toasts.chargingChanged)
                    Toaster.toast(qsTr("Đã cắm sạc"), qsTr("Pin đang sạc"), "power");
                for (const level of root.warnLevels)
                    level.warned = false;
            }
        }

        target: UPower
    }

    Connections {
        function onPercentageChanged(): void {
            if (!UPower.onBattery)
                return;

            const p = UPower.displayDevice.percentage * 100;
            for (const level of root.warnLevels) {
                if (p <= level.level && !level.warned) {
                    level.warned = true;
                    Toaster.toast(level.title ?? qsTr("Cảnh báo pin"), level.message ?? qsTr("Mức pin thấp"), level.icon ?? "battery_android_alert", level.critical ? Toast.Error : Toast.Warning);
                }
            }
        }

        target: UPower.displayDevice
    }

    Connections {
        function onHibernateDelayChanged(): void {
            if (hibernateTimer.running) {
                hibernateTimer.stop();
                root.syncAutoHibernate();
            }
        }

        target: GlobalConfig.general.battery
    }

    Timer {
        id: hibernateTimer

        interval: Math.max(0, GlobalConfig.general.battery.hibernateDelay) * 1000
        onTriggered: {
            if (root.shouldAutoHibernate)
                SessionManager.hibernate();
        }
    }
}
