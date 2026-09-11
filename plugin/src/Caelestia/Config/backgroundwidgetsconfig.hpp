#pragma once

#include "configobject.hpp"

namespace caelestia::config {

class ClockCookieConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, aiStyling, false)
    CONFIG_PROPERTY(int, sides, 14)
    CONFIG_PROPERTY(QString, dialNumberStyle, QStringLiteral("full"))
    CONFIG_PROPERTY(QString, hourHandStyle, QStringLiteral("fill"))
    CONFIG_PROPERTY(QString, minuteHandStyle, QStringLiteral("medium"))
    CONFIG_PROPERTY(QString, secondHandStyle, QStringLiteral("dot"))
    CONFIG_PROPERTY(QString, dateStyle, QStringLiteral("bubble"))
    CONFIG_PROPERTY(bool, timeIndicators, true)
    CONFIG_PROPERTY(bool, hourMarks, false)
    CONFIG_PROPERTY(bool, dateInClock, true)
    CONFIG_PROPERTY(bool, constantlyRotate, false)
    CONFIG_PROPERTY(bool, useSineCookie, false)

public:
    explicit ClockCookieConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addRangeConstraint(QStringLiteral("sides"), 0, 40);
        addEnumConstraint(QStringLiteral("dialNumberStyle"),
            { QStringLiteral("dots"), QStringLiteral("numbers"), QStringLiteral("full"),
                QStringLiteral("none") });
        addEnumConstraint(QStringLiteral("hourHandStyle"),
            { QStringLiteral("classic"), QStringLiteral("fill"), QStringLiteral("hollow"),
                QStringLiteral("hide") });
        addEnumConstraint(QStringLiteral("minuteHandStyle"),
            { QStringLiteral("classic"), QStringLiteral("thin"), QStringLiteral("medium"),
                QStringLiteral("bold"), QStringLiteral("hide") });
        addEnumConstraint(QStringLiteral("secondHandStyle"),
            { QStringLiteral("dot"), QStringLiteral("line"), QStringLiteral("classic"),
                QStringLiteral("hide") });
        addEnumConstraint(QStringLiteral("dateStyle"),
            { QStringLiteral("border"), QStringLiteral("rect"), QStringLiteral("bubble"),
                QStringLiteral("hide") });
    }
};

class DigitalClockFontConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(QString, family, QStringLiteral("Google Sans Flex"))
    CONFIG_PROPERTY(qreal, weight, 350)
    CONFIG_PROPERTY(qreal, width, 100)
    CONFIG_PROPERTY(qreal, size, 90)
    CONFIG_PROPERTY(qreal, roundness, 0)

public:
    explicit DigitalClockFontConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addRangeConstraint(QStringLiteral("weight"), 1, 1000);
        addRangeConstraint(QStringLiteral("width"), 25, 125);
        addRangeConstraint(QStringLiteral("size"), 1, 700);
        addRangeConstraint(QStringLiteral("roundness"), 0, 100);
    }
};

class DigitalClockConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, adaptiveAlignment, true)
    CONFIG_PROPERTY(bool, showDate, true)
    CONFIG_PROPERTY(bool, animateChange, true)
    CONFIG_PROPERTY(bool, vertical, false)
    CONFIG_SUBOBJECT(DigitalClockFontConfig, font)

public:
    explicit DigitalClockConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_font(new DigitalClockFontConfig(this)) {}
};

class ClockQuoteConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, false)
    CONFIG_PROPERTY(QString, text)
    CONFIG_PROPERTY(bool, followClock, false)

public:
    explicit ClockQuoteConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class WeatherWidgetConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, false)
    CONFIG_PROPERTY(QString, placementStrategy, QStringLiteral("free"))
    CONFIG_PROPERTY(qreal, x, 400)
    CONFIG_PROPERTY(qreal, y, 100)
    CONFIG_PROPERTY(QString, sizeMode, QStringLiteral("1x3"))

public:
    explicit WeatherWidgetConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addEnumConstraint(QStringLiteral("placementStrategy"),
            { QStringLiteral("free"), QStringLiteral("leastBusy"), QStringLiteral("mostBusy") });
        addRegexConstraint(QStringLiteral("sizeMode"), QRegularExpression(QStringLiteral("^\\d+x\\d+$")),
            QStringLiteral("must use a WIDTHxHEIGHT grid size"));
    }
};

class CalendarWidgetConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, false)
    CONFIG_PROPERTY(QString, placementStrategy, QStringLiteral("free"))
    CONFIG_PROPERTY(qreal, x, 400)
    CONFIG_PROPERTY(qreal, y, 100)
    CONFIG_PROPERTY(QString, sizeMode, QStringLiteral("2x2"))

public:
    explicit CalendarWidgetConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addEnumConstraint(QStringLiteral("placementStrategy"),
            { QStringLiteral("free"), QStringLiteral("leastBusy"), QStringLiteral("mostBusy") });
        addRegexConstraint(QStringLiteral("sizeMode"), QRegularExpression(QStringLiteral("^\\d+x\\d+$")),
            QStringLiteral("must use a WIDTHxHEIGHT grid size"));
    }
};

class WorldClockWidgetConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, false)
    CONFIG_PROPERTY(QStringList, timezones,
        { QStringLiteral("Australia/Sydney"), QStringLiteral("Asia/Tokyo"),
            QStringLiteral("Europe/London"), QStringLiteral("America/New_York") })
    CONFIG_PROPERTY(QString, placementStrategy, QStringLiteral("free"))
    CONFIG_PROPERTY(qreal, x, 400)
    CONFIG_PROPERTY(qreal, y, 100)
    CONFIG_PROPERTY(QString, sizeMode, QStringLiteral("2x2"))

public:
    explicit WorldClockWidgetConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addEnumConstraint(QStringLiteral("placementStrategy"),
            { QStringLiteral("free"), QStringLiteral("leastBusy"), QStringLiteral("mostBusy") });
        addRegexConstraint(QStringLiteral("sizeMode"), QRegularExpression(QStringLiteral("^\\d+x\\d+$")),
            QStringLiteral("must use a WIDTHxHEIGHT grid size"));
    }
};

class UserCardWidgetConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, false)
    CONFIG_PROPERTY(QString, placementStrategy, QStringLiteral("free"))
    CONFIG_PROPERTY(qreal, x, 400)
    CONFIG_PROPERTY(qreal, y, 100)

public:
    explicit UserCardWidgetConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addEnumConstraint(QStringLiteral("placementStrategy"),
            { QStringLiteral("free"), QStringLiteral("leastBusy"), QStringLiteral("mostBusy") });
    }
};

class ImagesWidgetConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, false)
    CONFIG_PROPERTY(QString, placementStrategy, QStringLiteral("free"))
    CONFIG_PROPERTY(qreal, x, 400)
    CONFIG_PROPERTY(qreal, y, 100)

public:
    explicit ImagesWidgetConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addEnumConstraint(QStringLiteral("placementStrategy"),
            { QStringLiteral("free"), QStringLiteral("leastBusy"), QStringLiteral("mostBusy") });
    }
};

class CustomImageWidgetConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, false)
    CONFIG_PROPERTY(QString, placementStrategy, QStringLiteral("free"))
    CONFIG_PROPERTY(qreal, x, 400)
    CONFIG_PROPERTY(qreal, y, 100)
    CONFIG_PROPERTY(QString, path)
    CONFIG_PROPERTY(QString, shape, QStringLiteral("Cookie4Sided"))
    CONFIG_PROPERTY(qreal, size, 200)

public:
    explicit CustomImageWidgetConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addEnumConstraint(QStringLiteral("placementStrategy"),
            { QStringLiteral("free"), QStringLiteral("leastBusy"), QStringLiteral("mostBusy") });
        addRangeConstraint(QStringLiteral("size"), 1, 2000);
    }
};

class ResourcesWidgetConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, false)
    CONFIG_PROPERTY(QString, placementStrategy, QStringLiteral("free"))
    CONFIG_PROPERTY(qreal, x, 400)
    CONFIG_PROPERTY(qreal, y, 100)
    CONFIG_PROPERTY(bool, vertical, false)

public:
    explicit ResourcesWidgetConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addEnumConstraint(QStringLiteral("placementStrategy"),
            { QStringLiteral("free"), QStringLiteral("leastBusy"), QStringLiteral("mostBusy") });
    }
};

class MediaWidgetConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, false)
    CONFIG_PROPERTY(bool, showControls, true)
    CONFIG_PROPERTY(bool, showLyrics, false)
    CONFIG_PROPERTY(bool, showTitles, true)
    CONFIG_PROPERTY(QString, backgroundShape, QStringLiteral("Cookie4Sided"))
    CONFIG_PROPERTY(QString, placementStrategy, QStringLiteral("free"))
    CONFIG_PROPERTY(qreal, x, 800)
    CONFIG_PROPERTY(qreal, y, 500)

public:
    explicit MediaWidgetConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addEnumConstraint(QStringLiteral("placementStrategy"),
            { QStringLiteral("free"), QStringLiteral("leastBusy"), QStringLiteral("mostBusy") });
    }
};

class DesktopWidgetsConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_SUBOBJECT(WeatherWidgetConfig, weather)
    CONFIG_SUBOBJECT(CalendarWidgetConfig, calendar)
    CONFIG_SUBOBJECT(WorldClockWidgetConfig, worldClock)
    CONFIG_SUBOBJECT(UserCardWidgetConfig, userCard)
    CONFIG_SUBOBJECT(ImagesWidgetConfig, images)
    CONFIG_SUBOBJECT(CustomImageWidgetConfig, customImage)
    CONFIG_SUBOBJECT(ResourcesWidgetConfig, resources)
    CONFIG_SUBOBJECT(MediaWidgetConfig, media)

public:
    explicit DesktopWidgetsConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_weather(new WeatherWidgetConfig(this))
        , m_calendar(new CalendarWidgetConfig(this))
        , m_worldClock(new WorldClockWidgetConfig(this))
        , m_userCard(new UserCardWidgetConfig(this))
        , m_images(new ImagesWidgetConfig(this))
        , m_customImage(new CustomImageWidgetConfig(this))
        , m_resources(new ResourcesWidgetConfig(this))
        , m_media(new MediaWidgetConfig(this)) {}
};

class BackgroundParallaxConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, vertical, false)
    CONFIG_PROPERTY(bool, autoVertical, false)
    CONFIG_PROPERTY(bool, enableWorkspace, true)
    CONFIG_PROPERTY(qreal, workspaceZoom, 1)
    CONFIG_PROPERTY(bool, enableSidebar, true)
    CONFIG_PROPERTY(qreal, widgetsFactor, 1.2)

public:
    explicit BackgroundParallaxConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addRangeConstraint(QStringLiteral("workspaceZoom"), 0.1, 4);
        addRangeConstraint(QStringLiteral("widgetsFactor"), 0, 10);
    }
};

} // namespace caelestia::config
