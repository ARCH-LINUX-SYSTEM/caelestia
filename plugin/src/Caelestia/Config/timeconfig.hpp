#pragma once

#include "configobject.hpp"

namespace caelestia::config {

class PomodoroConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(int, breakTime, 300)
    CONFIG_GLOBAL_PROPERTY(int, cyclesBeforeLongBreak, 4)
    CONFIG_GLOBAL_PROPERTY(int, focus, 1500)
    CONFIG_GLOBAL_PROPERTY(int, longBreak, 900)

public:
    explicit PomodoroConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addRangeConstraint(QStringLiteral("breakTime"), 1, 86400);
        addRangeConstraint(QStringLiteral("cyclesBeforeLongBreak"), 1, 100);
        addRangeConstraint(QStringLiteral("focus"), 1, 86400);
        addRangeConstraint(QStringLiteral("longBreak"), 1, 86400);
    }
};

class TimeConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    // Safety gate: existing Caelestia locale-based formatting remains the default.
    CONFIG_GLOBAL_PROPERTY(bool, useCustomFormats, false)
    CONFIG_GLOBAL_PROPERTY(QString, format, QStringLiteral("hh:mm"))
    CONFIG_GLOBAL_PROPERTY(QString, shortDateFormat, QStringLiteral("dd/MM"))
    CONFIG_GLOBAL_PROPERTY(QString, dateWithYearFormat, QStringLiteral("dd/MM/yyyy"))
    CONFIG_GLOBAL_PROPERTY(QString, dateFormat, QStringLiteral("ddd, dd/MM"))
    CONFIG_SUBOBJECT(PomodoroConfig, pomodoro)
    CONFIG_GLOBAL_PROPERTY(bool, secondPrecision, false)

public:
    explicit TimeConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_pomodoro(new PomodoroConfig(this)) {
        const auto nonEmpty = [](const QVariant& value) {
            return value.toString().trimmed().isEmpty() ? QStringLiteral("must not be empty") : QString();
        };
        addValidator(QStringLiteral("format"), nonEmpty);
        addValidator(QStringLiteral("shortDateFormat"), nonEmpty);
        addValidator(QStringLiteral("dateWithYearFormat"), nonEmpty);
        addValidator(QStringLiteral("dateFormat"), nonEmpty);
    }
};

} // namespace caelestia::config
