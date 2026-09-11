#pragma once

#include "configobject.hpp"

#include <qstring.h>
#include <qvariant.h>

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

class AudioProtectionConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(bool, enabled, false)
    CONFIG_GLOBAL_PROPERTY(qreal, maxIncrease, 0.1)

public:
    explicit AudioProtectionConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addRangeConstraint(QStringLiteral("maxIncrease"), 0, 1);
    }
};

class ServiceConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(QString, weatherLocation)
    CONFIG_GLOBAL_PROPERTY(bool, weatherUseGps, true)
    CONFIG_GLOBAL_PROPERTY(int, weatherFetchInterval, 10)
    // Guess based on locale
    CONFIG_GLOBAL_PROPERTY(bool, useFahrenheit,
        QLocale().measurementSystem() == QLocale::ImperialUSSystem ||
            QLocale().measurementSystem() == QLocale::ImperialUKSystem)
    // This is always false by default cause apparently even imperial system users don't use it for perf temps?
    CONFIG_GLOBAL_PROPERTY(bool, useFahrenheitPerformance, false)
    // Attempt to guess based on locale
    CONFIG_GLOBAL_PROPERTY(
        bool, useTwelveHourClock, QLocale().timeFormat(QLocale::ShortFormat).toLower().contains(u"a"_s))
    CONFIG_GLOBAL_PROPERTY(QString, gpuType)
    CONFIG_GLOBAL_PROPERTY(bool, pauseWallpaperOnBattery, true)
    CONFIG_GLOBAL_PROPERTY(bool, pauseWallpaperOnWindowOverlap, true)
    CONFIG_GLOBAL_PROPERTY(QString, wallpaperHwDecoder, u"vaapi"_s)
    CONFIG_GLOBAL_PROPERTY(int, visualiserBars, 60)
    CONFIG_GLOBAL_PROPERTY(qreal, audioIncrement, 0.1)
    CONFIG_GLOBAL_PROPERTY(qreal, brightnessIncrement, 0.1)
    CONFIG_GLOBAL_PROPERTY(qreal, maxVolume, 1.0)
    CONFIG_SUBOBJECT(AudioProtectionConfig, audioProtection)
    CONFIG_GLOBAL_PROPERTY(QString, calendarLocale, u"en-GB"_s)
    CONFIG_GLOBAL_PROPERTY(QString, networkUserAgent,
        u"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) "
        u"Chrome/123.0.0.0 Safari/537.36"_s)
    CONFIG_GLOBAL_PROPERTY(bool, filterDuplicatePlayers, true)
    CONFIG_GLOBAL_PROPERTY(bool, smartScheme, true)
    CONFIG_GLOBAL_PROPERTY(QString, defaultPlayer, u"Spotify"_s)
    CONFIG_GLOBAL_PROPERTY(QVariantList, playerAliases,
        { vmap({ { u"from"_s, u"com.github.th_ch.youtube_music"_s }, { u"to"_s, u"YT Music"_s } }) })
    CONFIG_GLOBAL_PROPERTY(QString, lyricsBackend, u"Auto"_s)

public:
    explicit ServiceConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_audioProtection(new AudioProtectionConfig(this)) {
        addEnumConstraint(QStringLiteral("wallpaperHwDecoder"),
            { QStringLiteral("auto"), QStringLiteral("none"), QStringLiteral("vaapi"),
                QStringLiteral("vdpau"), QStringLiteral("cuda"), QStringLiteral("vulkan"),
                QStringLiteral("drm") });
        addRangeConstraint(QStringLiteral("weatherFetchInterval"), 5, 1440);
        addRangeConstraint(QStringLiteral("visualiserBars"), 1, 500);
        addRangeConstraint(QStringLiteral("audioIncrement"), 0.001, 1);
        addRangeConstraint(QStringLiteral("brightnessIncrement"), 0.001, 1);
        addRangeConstraint(QStringLiteral("maxVolume"), 0, 2);
    }
};

} // namespace caelestia::config
