#pragma once

#include "configobject.hpp"

#include <qregularexpression.h>

namespace caelestia::config {

class PolicyConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(int, ai, 1)
    CONFIG_GLOBAL_PROPERTY(int, weeb, 1)

public:
    explicit PolicyConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addRangeConstraint(QStringLiteral("ai"), 0, 2);
        addRangeConstraint(QStringLiteral("weeb"), 0, 2);
    }
};

class AiConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(QString, systemPrompt,
        QStringLiteral(R"PROMPT(## Style
- Use casual tone, don't be formal!
- Always be brief and to the point, unless asked otherwise
- Don't repeat the user's question
- Be approachable: Avoid using overly complicated, domain-specific terms and provide analogies when asked to explain a concept

## Context (ignore when irrelevant)
- You are a helpful and inspiring sidebar assistant on a {DISTRO} Linux system
- Desktop environment: {DE}
- Current date & time: {DATETIME}
- Focused app: {WINDOWCLASS}

## Presentation
- Use Markdown features in your response: 
  - **Bold** text to **highlight keywords** in your response
  - **Split long information into small sections** with h2 headers and a relevant emoji at the start of it (for example `## 🐧 Linux`). Bullet points are preferred over long paragraphs, unless you're offering writing support or instructed otherwise by the user.
- Asked to compare different options? You should firstly use a table to compare the main aspects, then elaborate or include relevant comments from online forums *after* the table. Make sure to provide a final recommendation for the user's use case!
- Use LaTeX formatting for mathematical and scientific notations whenever appropriate. Enclose all LaTeX '$$' delimiters. NEVER generate LaTeX code in a latex block unless the user explicitly asks for it. DO NOT use LaTeX for regular documents (resumes, letters, essays, CVs, etc.).

Thanks!
)PROMPT"))
    CONFIG_GLOBAL_PROPERTY(QString, tool, QStringLiteral("functions"))
    CONFIG_GLOBAL_PROPERTY(QVariantList, extraModels,
        {
            vmap({
                { QStringLiteral("api_format"), QStringLiteral("openai") },
                { QStringLiteral("description"),
                    QStringLiteral("DeepSeek R1 Distill LLaMA 70B custom model") },
                { QStringLiteral("endpoint"),
                    QStringLiteral("https://openrouter.ai/api/v1/chat/completions") },
                { QStringLiteral("homepage"),
                    QStringLiteral("https://openrouter.ai/deepseek/deepseek-r1-distill-llama-70b:free") },
                { QStringLiteral("icon"), QStringLiteral("spark-symbolic") },
                { QStringLiteral("key_get_link"), QStringLiteral("https://openrouter.ai/settings/keys") },
                { QStringLiteral("key_id"), QStringLiteral("openrouter") },
                { QStringLiteral("model"),
                    QStringLiteral("deepseek/deepseek-r1-distill-llama-70b:free") },
                { QStringLiteral("name"), QStringLiteral("Custom: DS R1 Dstl. LLaMA 70B") },
                { QStringLiteral("requires_key"), true },
            }),
        })

public:
    explicit AiConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addEnumConstraint(QStringLiteral("tool"),
            { QStringLiteral("search"), QStringLiteral("functions"), QStringLiteral("none") });
        addValidator(QStringLiteral("extraModels"), [](const QVariant& value) {
            const auto models = value.toList();
            for (const auto& modelValue : models) {
                const auto model = modelValue.toMap();
                if (model.isEmpty())
                    return QStringLiteral("must contain only model objects");
                for (const auto& required :
                    { QStringLiteral("api_format"), QStringLiteral("endpoint"), QStringLiteral("model"),
                        QStringLiteral("name") }) {
                    if (model.value(required).toString().isEmpty())
                        return QStringLiteral("each model must define api_format, endpoint, model and name");
                }
            }
            return QString();
        });
    }
};

class ConflictKillerConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(bool, autoKillNotificationDaemons, false)
    CONFIG_GLOBAL_PROPERTY(bool, autoKillTrays, false)

public:
    explicit ConflictKillerConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class CrosshairConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(QString, code, QStringLiteral("0;P;d;1;0l;10;0o;2;1b;0"))

public:
    explicit CrosshairConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class DockConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(bool, enabled, false)
    CONFIG_GLOBAL_PROPERTY(bool, showBackground, true)
    CONFIG_GLOBAL_PROPERTY(bool, showPinButton, true)
    CONFIG_GLOBAL_PROPERTY(bool, showAppsButton, true)
    CONFIG_GLOBAL_PROPERTY(bool, showMedia, true)
    CONFIG_GLOBAL_PROPERTY(bool, monochromeIcons, true)
    CONFIG_GLOBAL_PROPERTY(qreal, height, 60)
    CONFIG_GLOBAL_PROPERTY(qreal, hoverRegionHeight, 2)
    CONFIG_GLOBAL_PROPERTY(bool, pinnedOnStartup, false)
    CONFIG_GLOBAL_PROPERTY(bool, hoverToReveal, true)
    CONFIG_GLOBAL_PROPERTY(QStringList, pinnedApps,
        { QStringLiteral("org.kde.dolphin"), QStringLiteral("kitty") })
    CONFIG_GLOBAL_PROPERTY(QStringList, ignoredAppRegexes)

public:
    explicit DockConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addRangeConstraint(QStringLiteral("height"), 1, 300);
        addRangeConstraint(QStringLiteral("hoverRegionHeight"), 0, 100);
        addValidator(QStringLiteral("ignoredAppRegexes"), [](const QVariant& value) {
            for (const auto& pattern : value.toStringList()) {
                const QRegularExpression expression(pattern);
                if (!expression.isValid())
                    return QStringLiteral("must contain only valid regular expressions");
            }
            return QString();
        });
    }
};

class NightLightConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(bool, automatic, true)
    CONFIG_GLOBAL_PROPERTY(QString, from, QStringLiteral("19:00"))
    CONFIG_GLOBAL_PROPERTY(QString, to, QStringLiteral("06:30"))
    CONFIG_GLOBAL_PROPERTY(int, colorTemperature, 5000)

public:
    explicit NightLightConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        const QRegularExpression timeExpression(
            QStringLiteral("^(?:[01]\\d|2[0-3]):[0-5]\\d$"));
        addRegexConstraint(
            QStringLiteral("from"), timeExpression, QStringLiteral("must use 24-hour HH:mm format"));
        addRegexConstraint(
            QStringLiteral("to"), timeExpression, QStringLiteral("must use 24-hour HH:mm format"));
        addRangeConstraint(QStringLiteral("colorTemperature"), 1000, 10000);
    }
};

class AntiFlashbangConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(bool, enabled, false)

public:
    explicit AntiFlashbangConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class LightConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_SUBOBJECT(NightLightConfig, night)
    CONFIG_SUBOBJECT(AntiFlashbangConfig, antiFlashbang)

public:
    explicit LightConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_night(new NightLightConfig(this))
        , m_antiFlashbang(new AntiFlashbangConfig(this)) {}
};

class OskConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(QString, layout, QStringLiteral("qwerty_full"))
    CONFIG_GLOBAL_PROPERTY(bool, pinnedOnStartup, false)

public:
    explicit OskConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class FloatingImageConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(QString, imageSource,
        QStringLiteral("https://media.tenor.com/H5U5bJzj3oAAAAAi/kukuru.gif"))
    CONFIG_GLOBAL_PROPERTY(qreal, scale, 0.5)

public:
    explicit FloatingImageConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addRangeConstraint(QStringLiteral("scale"), 0.05, 4);
    }
};

class OverlayConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(bool, openingZoomAnimation, true)
    CONFIG_GLOBAL_PROPERTY(bool, darkenScreen, true)
    CONFIG_GLOBAL_PROPERTY(qreal, clickthroughOpacity, 0.8)
    CONFIG_SUBOBJECT(FloatingImageConfig, floatingImage)

public:
    explicit OverlayConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_floatingImage(new FloatingImageConfig(this)) {
        addRangeConstraint(QStringLiteral("clickthroughOpacity"), 0, 1);
    }
};

class MusicRecognitionConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(int, timeout, 16)
    CONFIG_GLOBAL_PROPERTY(int, interval, 4)

public:
    explicit MusicRecognitionConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addRangeConstraint(QStringLiteral("timeout"), 10, 100);
        addRangeConstraint(QStringLiteral("interval"), 2, 10);
    }
};

class SoundsConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(bool, battery, false)
    CONFIG_GLOBAL_PROPERTY(bool, pomodoro, false)
    CONFIG_GLOBAL_PROPERTY(QString, theme, QStringLiteral("freedesktop"))

public:
    explicit SoundsConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class UpdatesConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(bool, enableCheck, true)
    CONFIG_GLOBAL_PROPERTY(int, checkInterval, 120)
    CONFIG_GLOBAL_PROPERTY(int, adviseUpdateThreshold, 75)
    CONFIG_GLOBAL_PROPERTY(int, stronglyAdviseUpdateThreshold, 200)

public:
    explicit UpdatesConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addRangeConstraint(QStringLiteral("checkInterval"), 60, 1440);
        addRangeConstraint(QStringLiteral("adviseUpdateThreshold"), 0, 100000);
        addRangeConstraint(QStringLiteral("stronglyAdviseUpdateThreshold"), 0, 100000);
    }
};

class HacksConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(int, arbitraryRaceConditionDelay, 20)

public:
    explicit HacksConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        addRangeConstraint(QStringLiteral("arbitraryRaceConditionDelay"), 0, 5000);
    }
};

class WorkSafetyEnableConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(bool, wallpaper, false)
    CONFIG_GLOBAL_PROPERTY(bool, clipboard, false)

public:
    explicit WorkSafetyEnableConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class WorkSafetyTriggerConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(QStringList, networkNameKeywords,
        { QStringLiteral("airport"), QStringLiteral("cafe"), QStringLiteral("college"),
            QStringLiteral("company"), QStringLiteral("eduroam"), QStringLiteral("free"),
            QStringLiteral("guest"), QStringLiteral("public"), QStringLiteral("school"),
            QStringLiteral("university") })
    CONFIG_GLOBAL_PROPERTY(QStringList, fileKeywords,
        { QStringLiteral("anime"), QStringLiteral("booru"), QStringLiteral("ecchi"),
            QStringLiteral("hentai"), QStringLiteral("yande.re"), QStringLiteral("konachan"),
            QStringLiteral("breast"), QStringLiteral("nipples"), QStringLiteral("pussy"),
            QStringLiteral("nsfw"), QStringLiteral("spoiler"), QStringLiteral("girl") })
    CONFIG_GLOBAL_PROPERTY(QStringList, linkKeywords,
        { QStringLiteral("hentai"), QStringLiteral("porn"), QStringLiteral("sukebei"),
            QStringLiteral("hitomi.la"), QStringLiteral("rule34"), QStringLiteral("gelbooru"),
            QStringLiteral("fanbox"), QStringLiteral("dlsite") })

public:
    explicit WorkSafetyTriggerConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class WorkSafetyConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_SUBOBJECT(WorkSafetyEnableConfig, enable)
    CONFIG_SUBOBJECT(WorkSafetyTriggerConfig, triggerCondition)

public:
    explicit WorkSafetyConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_enable(new WorkSafetyEnableConfig(this))
        , m_triggerCondition(new WorkSafetyTriggerConfig(this)) {}
};

} // namespace caelestia::config
