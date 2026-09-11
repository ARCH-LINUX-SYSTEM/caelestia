#pragma once

#include "configobject.hpp"

namespace caelestia::config {

class SearchPrefixConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    // Disabled by default so adding end4-compatible search actions does not
    // change Caelestia's existing launcher results until explicitly enabled.
    CONFIG_GLOBAL_PROPERTY(bool, showDefaultActionsWithoutPrefix, false)
    CONFIG_GLOBAL_PROPERTY(QString, app)
    CONFIG_GLOBAL_PROPERTY(QString, clipboard, QStringLiteral(";"))
    CONFIG_GLOBAL_PROPERTY(QString, emojis, QStringLiteral(":"))
    CONFIG_GLOBAL_PROPERTY(QString, keybinds, QStringLiteral("<"))
    CONFIG_GLOBAL_PROPERTY(QString, symbols, QStringLiteral("."))
    CONFIG_GLOBAL_PROPERTY(QString, math, QStringLiteral("="))
    CONFIG_GLOBAL_PROPERTY(QString, shellCommand, QStringLiteral("$"))
    CONFIG_GLOBAL_PROPERTY(QString, webSearch, QStringLiteral("?"))

public:
    explicit SearchPrefixConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        const auto prefixValidator = [](const QVariant& value) {
            const auto prefix = value.toString();
            if (prefix.size() > 8 || prefix.contains(QRegularExpression(QStringLiteral("\\s"))))
                return QStringLiteral("must be at most 8 characters and contain no whitespace");
            return QString();
        };
        for (const auto& name :
            { QStringLiteral("app"), QStringLiteral("clipboard"), QStringLiteral("emojis"),
                QStringLiteral("keybinds"), QStringLiteral("symbols"), QStringLiteral("math"),
                QStringLiteral("shellCommand"), QStringLiteral("webSearch") }) {
            addValidator(name, prefixValidator);
        }
    }
};

class ImageSearchConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(QString, imageSearchEngineBaseUrl,
        QStringLiteral("https://lens.google.com/uploadbyurl?url="))
    CONFIG_GLOBAL_PROPERTY(bool, useCircleSelection, false)

public:
    explicit ImageSearchConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addRegexConstraint(QStringLiteral("imageSearchEngineBaseUrl"),
            QRegularExpression(QStringLiteral("^https?://.+")),
            QStringLiteral("must be an HTTP or HTTPS URL"));
    }
};

class SearchConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(int, nonAppResultDelay, 30)
    CONFIG_GLOBAL_PROPERTY(QString, engineBaseUrl, QStringLiteral("https://www.google.com/search?q="))
    CONFIG_GLOBAL_PROPERTY(QStringList, excludedSites,
        { QStringLiteral("quora.com"), QStringLiteral("facebook.com") })
    CONFIG_GLOBAL_PROPERTY(bool, sloppy, false)
    CONFIG_SUBOBJECT(SearchPrefixConfig, prefix)
    CONFIG_SUBOBJECT(ImageSearchConfig, imageSearch)

public:
    explicit SearchConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_prefix(new SearchPrefixConfig(this))
        , m_imageSearch(new ImageSearchConfig(this)) {
        addRangeConstraint(QStringLiteral("nonAppResultDelay"), 0, 5000);
        addRegexConstraint(QStringLiteral("engineBaseUrl"),
            QRegularExpression(QStringLiteral("^https?://.+")),
            QStringLiteral("must be an HTTP or HTTPS URL"));
    }
};

} // namespace caelestia::config
