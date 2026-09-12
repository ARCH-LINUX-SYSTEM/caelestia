pragma Singleton

import QtQuick
import Quickshell
import Caelestia.Config

Singleton {
    property alias enabled: clock.enabled
    readonly property date date: clock.date
    readonly property int hours: clock.hours
    readonly property int minutes: clock.minutes
    readonly property int seconds: clock.seconds

    readonly property string timeFormat: GlobalConfig.time.useCustomFormats ? GlobalConfig.time.format : (GlobalConfig.services.useTwelveHourClock ? "hh:mm:A" : "hh:mm")
    readonly property string timeStr: format(timeFormat)
    readonly property string shortDateStr: format(GlobalConfig.time.shortDateFormat)
    readonly property string dateWithYearStr: format(GlobalConfig.time.dateWithYearFormat)
    readonly property string dateStr: format(GlobalConfig.time.dateFormat)
    readonly property list<string> timeComponents: timeStr.split(":")
    readonly property string hourStr: timeComponents[0] ?? ""
    readonly property string minuteStr: timeComponents[1] ?? ""
    readonly property string amPmStr: timeComponents[2] ?? ""
    readonly property string secondStr: seconds < 10 ? "0" + seconds : String(seconds)

    function format(fmt: string): string {
        return Qt.formatDateTime(clock.date, fmt);
    }

    SystemClock {
        id: clock

        precision: GlobalConfig.time.secondPrecision ? SystemClock.Seconds : SystemClock.Minutes
    }
}
