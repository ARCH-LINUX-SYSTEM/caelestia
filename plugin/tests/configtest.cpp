#include "configmigration.hpp"
#include "configobject.hpp"

#include <qjsonarray.h>
#include <qjsonobject.h>
#include <qtest.h>

using namespace caelestia::config;

class ValidatedConfig final : public ConfigObject {
    Q_OBJECT

    CONFIG_PROPERTY(int, amount, 5)
    CONFIG_PROPERTY(QString, mode, QStringLiteral("auto"))

public:
    explicit ValidatedConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addRangeConstraint(QStringLiteral("amount"), 0, 10);
        addEnumConstraint(
            QStringLiteral("mode"), { QStringLiteral("auto"), QStringLiteral("manual") });
    }
};

class ConfigTest final : public QObject {
    Q_OBJECT

private slots:
    void validationAcceptsValidJson();
    void validationRejectsInvalidRange();
    void validationRejectsInvalidEnum();
    void runtimeSetterRejectsInvalidValue();
    void migrationMapsAliasesAndUnits();
    void migrationPreservesCanonicalAndUnknownValues();
    void migrationAddsOptionalBarEntries();
    void migrationMapsEnd4PortAliases();
    void migrationKeepsCanonicalPortValues();
    void migrationRejectsFutureVersion();
};

void ConfigTest::validationAcceptsValidJson() {
    ValidatedConfig config;
    const QJsonObject json{
        { QStringLiteral("amount"), 8 },
        { QStringLiteral("mode"), QStringLiteral("manual") },
    };

    QCOMPARE(config.validateJson(json), QString());
}

void ConfigTest::validationRejectsInvalidRange() {
    ValidatedConfig config;
    const auto error = config.validateJson({ { QStringLiteral("amount"), 11 } });

    QVERIFY(error.contains(QStringLiteral("amount")));
    QVERIFY(error.contains(QStringLiteral("between 0 and 10")));
}

void ConfigTest::validationRejectsInvalidEnum() {
    ValidatedConfig config;
    const auto error = config.validateJson({ { QStringLiteral("mode"), QStringLiteral("other") } });

    QVERIFY(error.contains(QStringLiteral("mode")));
    QVERIFY(error.contains(QStringLiteral("auto, manual")));
}

void ConfigTest::runtimeSetterRejectsInvalidValue() {
    ValidatedConfig config;

    config.set_amount(20);
    QCOMPARE(config.amount(), 5);

    config.set_amount(7);
    QCOMPARE(config.amount(), 7);
}

void ConfigTest::migrationMapsAliasesAndUnits() {
    QJsonObject source{
        { QStringLiteral("audio"),
            QJsonObject{
                { QStringLiteral("protection"),
                    QJsonObject{
                        { QStringLiteral("enable"), true },
                        { QStringLiteral("maxAllowedIncrease"), 10 },
                        { QStringLiteral("maxAllowed"), 125 },
                    } },
            } },
        { QStringLiteral("notifications"), QJsonObject{ { QStringLiteral("timeout"), 7000 } } },
        { QStringLiteral("osd"), QJsonObject{ { QStringLiteral("timeout"), 1000 } } },
        { QStringLiteral("launcher"),
            QJsonObject{
                { QStringLiteral("pinnedApps"),
                    QJsonArray{ QStringLiteral("org.kde.dolphin"), QStringLiteral("kitty") } },
            } },
    };

    const auto result = migrateGlobalConfig(source, 0);
    QVERIFY2(result.error.isEmpty(), qPrintable(result.error));

    const auto services = result.config.value(QStringLiteral("services")).toObject();
    const auto protection = services.value(QStringLiteral("audioProtection")).toObject();
    QCOMPARE(protection.value(QStringLiteral("enabled")).toBool(), true);
    QCOMPARE(protection.value(QStringLiteral("maxIncrease")).toDouble(), 0.1);
    QCOMPARE(services.value(QStringLiteral("maxVolume")).toDouble(), 1.25);
    QCOMPARE(result.config.value(QStringLiteral("notifs"))
                 .toObject()
                 .value(QStringLiteral("defaultExpireTimeout"))
                 .toInt(),
        7000);
    QCOMPARE(result.config.value(QStringLiteral("osd"))
                 .toObject()
                 .value(QStringLiteral("hideDelay"))
                 .toInt(),
        1000);
    QCOMPARE(result.config.value(QStringLiteral("launcher"))
                 .toObject()
                 .value(QStringLiteral("favouriteApps"))
                 .toArray()
                 .size(),
        2);
}

void ConfigTest::migrationPreservesCanonicalAndUnknownValues() {
    QJsonObject source{
        { QStringLiteral("services"),
            QJsonObject{
                { QStringLiteral("maxVolume"), 0.8 },
                { QStringLiteral("futureServiceOption"), QStringLiteral("keep") },
            } },
        { QStringLiteral("audio"),
            QJsonObject{
                { QStringLiteral("protection"), QJsonObject{ { QStringLiteral("maxAllowed"), 150 } } },
                { QStringLiteral("futureAudioOption"), 42 },
            } },
        { QStringLiteral("futureTopLevel"), QJsonObject{ { QStringLiteral("value"), true } } },
    };

    const auto result = migrateGlobalConfig(source, 0);
    QVERIFY2(result.error.isEmpty(), qPrintable(result.error));

    const auto services = result.config.value(QStringLiteral("services")).toObject();
    QCOMPARE(services.value(QStringLiteral("maxVolume")).toDouble(), 0.8);
    QCOMPARE(services.value(QStringLiteral("futureServiceOption")).toString(), QStringLiteral("keep"));
    QCOMPARE(result.config.value(QStringLiteral("audio"))
                 .toObject()
                 .value(QStringLiteral("futureAudioOption"))
                 .toInt(),
        42);
    QCOMPARE(result.config.value(QStringLiteral("futureTopLevel"))
                 .toObject()
                 .value(QStringLiteral("value"))
                 .toBool(),
        true);
}

void ConfigTest::migrationAddsOptionalBarEntries() {
    const QJsonObject source{
        { QStringLiteral("bar"),
            QJsonObject{
                { QStringLiteral("entries"),
                    QJsonArray{
                        QJsonObject{
                            { QStringLiteral("id"), QStringLiteral("clock") },
                            { QStringLiteral("enabled"), true },
                        },
                        QJsonObject{
                            { QStringLiteral("id"), QStringLiteral("weather") },
                            { QStringLiteral("enabled"), true },
                        },
                    } },
            } },
    };

    const auto result = migrateGlobalConfig(source, 1);
    QVERIFY2(result.error.isEmpty(), qPrintable(result.error));

    const auto entries =
        result.config.value(QStringLiteral("bar")).toObject().value(QStringLiteral("entries")).toArray();
    QCOMPARE(entries.size(), 3);
    QCOMPARE(entries.at(1).toObject().value(QStringLiteral("id")).toString(), QStringLiteral("weather"));
    QCOMPARE(entries.at(1).toObject().value(QStringLiteral("enabled")).toBool(), true);
    QCOMPARE(entries.at(2).toObject().value(QStringLiteral("id")).toString(), QStringLiteral("resources"));
    QCOMPARE(entries.at(2).toObject().value(QStringLiteral("enabled")).toBool(), false);
}

void ConfigTest::migrationMapsEnd4PortAliases() {
    const QJsonObject source{
        { QStringLiteral("appearance"),
            QJsonObject{
                { QStringLiteral("fonts"),
                    QJsonObject{
                        { QStringLiteral("main"), QStringLiteral("Inter") },
                        { QStringLiteral("title"), QStringLiteral("Manrope") },
                    } },
                { QStringLiteral("transparency"),
                    QJsonObject{
                        { QStringLiteral("enable"), true },
                        { QStringLiteral("backgroundTransparency"), 0.2 },
                    } },
                { QStringLiteral("palette"),
                    QJsonObject{ { QStringLiteral("accentColor"), QStringLiteral("AABBCC") } } },
            } },
        { QStringLiteral("apps"), QJsonObject{ { QStringLiteral("terminal"), QStringLiteral("foot -e fish") } } },
        { QStringLiteral("background"),
            QJsonObject{
                { QStringLiteral("widgets"),
                    QJsonObject{
                        { QStringLiteral("clock"),
                            QJsonObject{
                                { QStringLiteral("enable"), true },
                                { QStringLiteral("style"), QStringLiteral("digital") },
                            } },
                        { QStringLiteral("visualizer"),
                            QJsonObject{ { QStringLiteral("enable"), true } } },
                    } },
            } },
        { QStringLiteral("battery"),
            QJsonObject{
                { QStringLiteral("low"), 25 },
                { QStringLiteral("critical"), 7 },
                { QStringLiteral("full"), 95 },
            } },
        { QStringLiteral("tray"),
            QJsonObject{
                { QStringLiteral("monochromeIcons"), true },
                { QStringLiteral("filterPassive"), false },
            } },
        { QStringLiteral("search"),
            QJsonObject{
                { QStringLiteral("prefix"),
                    QJsonObject{
                        { QStringLiteral("action"), QStringLiteral("/") },
                        { QStringLiteral("app"), QStringLiteral(">") },
                    } },
            } },
        { QStringLiteral("sidebar"),
            QJsonObject{
                { QStringLiteral("quickToggles"),
                    QJsonObject{
                        { QStringLiteral("android"),
                            QJsonObject{
                                { QStringLiteral("columns"), 4 },
                                { QStringLiteral("toggles"),
                                    QJsonArray{
                                        QJsonObject{
                                            { QStringLiteral("type"), QStringLiteral("network") },
                                            { QStringLiteral("size"), 2 },
                                        },
                                        QJsonObject{
                                            { QStringLiteral("type"), QStringLiteral("bluetooth") },
                                            { QStringLiteral("size"), 2 },
                                        },
                                    } },
                            } },
                    } },
            } },
        { QStringLiteral("wallpaperSelector"),
            QJsonObject{
                { QStringLiteral("showSearchbar"), false },
                { QStringLiteral("columns"), 6 },
                { QStringLiteral("changeInterval"), 900000 },
            } },
    };

    const auto result = migrateGlobalConfig(source, 2);
    QVERIFY2(result.error.isEmpty(), qPrintable(result.error));

    const auto appearance = result.config.value(QStringLiteral("appearance")).toObject();
    const auto font = appearance.value(QStringLiteral("font")).toObject();
    QCOMPARE(font.value(QStringLiteral("body")).toObject().value(QStringLiteral("family")).toString(),
        QStringLiteral("Inter"));
    QCOMPARE(font.value(QStringLiteral("label")).toObject().value(QStringLiteral("family")).toString(),
        QStringLiteral("Inter"));
    QCOMPARE(font.value(QStringLiteral("title")).toObject().value(QStringLiteral("family")).toString(),
        QStringLiteral("Manrope"));
    QCOMPARE(
        appearance.value(QStringLiteral("transparency")).toObject().value(QStringLiteral("base")).toDouble(),
        0.8);
    QCOMPARE(appearance.value(QStringLiteral("palette"))
                 .toObject()
                 .value(QStringLiteral("accentColor"))
                 .toString(),
        QStringLiteral("#AABBCC"));

    const auto terminal = result.config.value(QStringLiteral("general"))
                              .toObject()
                              .value(QStringLiteral("apps"))
                              .toObject()
                              .value(QStringLiteral("terminal"))
                              .toArray();
    QCOMPARE(terminal, QJsonArray({ QStringLiteral("foot"), QStringLiteral("-e"), QStringLiteral("fish") }));

    const auto background = result.config.value(QStringLiteral("background")).toObject();
    QCOMPARE(background.value(QStringLiteral("desktopClock"))
                 .toObject()
                 .value(QStringLiteral("enabled"))
                 .toBool(),
        true);
    QCOMPARE(background.value(QStringLiteral("desktopClock"))
                 .toObject()
                 .value(QStringLiteral("style"))
                 .toString(),
        QStringLiteral("digital"));
    QCOMPARE(background.value(QStringLiteral("visualiser"))
                 .toObject()
                 .value(QStringLiteral("enabled"))
                 .toBool(),
        true);

    const auto battery =
        result.config.value(QStringLiteral("general")).toObject().value(QStringLiteral("battery")).toObject();
    QCOMPARE(battery.value(QStringLiteral("warnLevels")).toArray().size(), 2);
    QCOMPARE(battery.value(QStringLiteral("fullLevel")).toInt(), 95);
    QCOMPARE(result.config.value(QStringLiteral("bar"))
                 .toObject()
                 .value(QStringLiteral("tray"))
                 .toObject()
                 .value(QStringLiteral("recolour"))
                 .toBool(),
        true);
    QCOMPARE(result.config.value(QStringLiteral("launcher"))
                 .toObject()
                 .value(QStringLiteral("actionPrefix"))
                 .toString(),
        QStringLiteral("/"));

    const auto utilities = result.config.value(QStringLiteral("utilities")).toObject();
    QCOMPARE(utilities.value(QStringLiteral("quickToggleColumns")).toInt(), 4);
    const auto toggles = utilities.value(QStringLiteral("quickToggles")).toArray();
    QCOMPARE(toggles.at(0).toObject().value(QStringLiteral("id")).toString(), QStringLiteral("wifi"));
    QCOMPARE(toggles.at(0).toObject().value(QStringLiteral("enabled")).toBool(), true);

    const auto nexus = result.config.value(QStringLiteral("nexus")).toObject();
    QCOMPARE(nexus.value(QStringLiteral("showWallpaperSearch")).toBool(), false);
    QCOMPARE(nexus.value(QStringLiteral("wallpapersPerRow")).toInt(), 6);
    QCOMPARE(nexus.value(QStringLiteral("wallpaperChangeInterval")).toInt(), 15);
}

void ConfigTest::migrationKeepsCanonicalPortValues() {
    const QJsonObject source{
        { QStringLiteral("appearance"),
            QJsonObject{
                { QStringLiteral("font"),
                    QJsonObject{
                        { QStringLiteral("body"),
                            QJsonObject{ { QStringLiteral("family"), QStringLiteral("Canonical") } } },
                    } },
                { QStringLiteral("fonts"),
                    QJsonObject{ { QStringLiteral("main"), QStringLiteral("Legacy") } } },
            } },
        { QStringLiteral("nexus"),
            QJsonObject{ { QStringLiteral("wallpapersPerRow"), 8 } } },
        { QStringLiteral("wallpaperSelector"),
            QJsonObject{ { QStringLiteral("columns"), 3 } } },
    };

    const auto result = migrateGlobalConfig(source, 2);
    QVERIFY2(result.error.isEmpty(), qPrintable(result.error));
    QCOMPARE(result.config.value(QStringLiteral("appearance"))
                 .toObject()
                 .value(QStringLiteral("font"))
                 .toObject()
                 .value(QStringLiteral("body"))
                 .toObject()
                 .value(QStringLiteral("family"))
                 .toString(),
        QStringLiteral("Canonical"));
    QCOMPARE(result.config.value(QStringLiteral("nexus"))
                 .toObject()
                 .value(QStringLiteral("wallpapersPerRow"))
                 .toInt(),
        8);
    QVERIFY(!result.config.contains(QStringLiteral("wallpaperSelector")));
}

void ConfigTest::migrationRejectsFutureVersion() {
    const auto result = migrateGlobalConfig({}, CurrentGlobalConfigVersion + 1);
    QVERIFY(!result.error.isEmpty());
}

QTEST_GUILESS_MAIN(ConfigTest)

#include "configtest.moc"
