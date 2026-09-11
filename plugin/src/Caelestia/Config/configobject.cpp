#include "configobject.hpp"

#include <cmath>
#include <limits>
#include <qjsonarray.h>
#include <qjsonvalue.h>
#include <qlist.h>
#include <qloggingcategory.h>
#include <qmetaobject.h>
#include <qscopedvaluerollback.h>
#include <qstringlist.h>
#include <qvariant.h>

namespace caelestia::config {

namespace {

bool convertJsonValue(const QMetaType& type, const QJsonValue& jsonValue, QVariant& value) {
    const auto typeId = type.id();

    if (typeId == QMetaType::QStringList) {
        if (!jsonValue.isArray())
            return false;

        QStringList list;
        const auto array = jsonValue.toArray();
        list.reserve(array.size());
        for (const auto& item : array) {
            if (!item.isString())
                return false;
            list.append(item.toString());
        }
        value = list;
        return true;
    }

    if (typeId == QMetaType::fromType<QList<qreal>>().id()) {
        if (!jsonValue.isArray())
            return false;

        QList<qreal> list;
        const auto array = jsonValue.toArray();
        list.reserve(array.size());
        for (const auto& item : array) {
            const auto number = item.toDouble(std::numeric_limits<double>::quiet_NaN());
            if (!item.isDouble() || !std::isfinite(number))
                return false;
            list.append(number);
        }
        value = QVariant::fromValue(list);
        return true;
    }

    switch (typeId) {
    case QMetaType::Bool:
        if (!jsonValue.isBool())
            return false;
        value = jsonValue.toBool();
        return true;
    case QMetaType::Int: {
        const auto number = jsonValue.toDouble(std::numeric_limits<double>::quiet_NaN());
        if (!jsonValue.isDouble() || !std::isfinite(number) || std::floor(number) < number
            || number < std::numeric_limits<int>::min() || number > std::numeric_limits<int>::max())
            return false;
        value = static_cast<int>(number);
        return true;
    }
    case QMetaType::Double: {
        const auto number = jsonValue.toDouble(std::numeric_limits<double>::quiet_NaN());
        if (!jsonValue.isDouble() || !std::isfinite(number))
            return false;
        value = number;
        return true;
    }
    case QMetaType::Float: {
        const auto number = jsonValue.toDouble(std::numeric_limits<double>::quiet_NaN());
        if (!jsonValue.isDouble() || !std::isfinite(number)
            || std::abs(number) > static_cast<double>(std::numeric_limits<float>::max()))
            return false;
        value = static_cast<float>(number);
        return true;
    }
    case QMetaType::QString:
        if (!jsonValue.isString())
            return false;
        value = jsonValue.toString();
        return true;
    case QMetaType::QVariantList:
        if (!jsonValue.isArray())
            return false;
        value = jsonValue.toArray().toVariantList();
        return true;
    case QMetaType::QVariantMap:
        if (!jsonValue.isObject())
            return false;
        value = jsonValue.toObject().toVariantMap();
        return true;
    default:
        return false;
    }
}

} // namespace

Q_LOGGING_CATEGORY(lcConfig, "caelestia.config", QtInfoMsg)

// ConfigObject

ConfigObject::ConfigObject(QObject* parent)
    : QObject(parent) {}

void ConfigObject::addValidator(const QString& name, ValueValidator validator) {
    m_validators.insert(name, std::move(validator));
}

void ConfigObject::addRangeConstraint(const QString& name, qreal minimum, qreal maximum) {
    addValidator(name, [minimum, maximum](const QVariant& value) {
        bool ok = false;
        const auto number = value.toDouble(&ok);
        if (!ok || !std::isfinite(number))
            return QStringLiteral("must be a finite number");
        if (number < minimum || number > maximum) {
            return QStringLiteral("must be between %1 and %2")
                .arg(QString::number(minimum), QString::number(maximum));
        }
        return QString();
    });
}

void ConfigObject::addEnumConstraint(const QString& name, const QStringList& values) {
    addValidator(name, [values](const QVariant& value) {
        const auto string = value.toString();
        if (!values.contains(string)) {
            return QStringLiteral("must be one of: %1").arg(values.join(QStringLiteral(", ")));
        }
        return QString();
    });
}

void ConfigObject::addRegexConstraint(
    const QString& name, const QRegularExpression& expression, const QString& description) {
    addValidator(name, [expression, description](const QVariant& value) {
        if (!expression.match(value.toString()).hasMatch())
            return description;
        return QString();
    });
}

QString ConfigObject::validatePropertyValue(const QString& name, const QVariant& value) const {
    const auto validator = m_validators.constFind(name);
    if (validator == m_validators.cend())
        return {};

    const auto detail = validator.value()(value);
    if (detail.isEmpty())
        return {};

    return QStringLiteral("Invalid value for option '%1': %2").arg(propertyPath(name), detail);
}

QString ConfigObject::validateJson(const QJsonObject& obj) const {
    const auto* meta = metaObject();

    for (int i = basePropertyOffset(); i < meta->propertyCount(); ++i) {
        const auto prop = meta->property(i);
        const auto key = QString::fromUtf8(prop.name());

        if (!obj.contains(key) || isGlobalOnly(key))
            continue;

        const auto jsonValue = obj.value(key);
        auto* const subObj = prop.read(this).value<ConfigObject*>();
        if (subObj) {
            if (!jsonValue.isObject())
                return QStringLiteral("Option '%1' must be a JSON object").arg(propertyPath(key));
            const auto error = subObj->validateJson(jsonValue.toObject());
            if (!error.isEmpty())
                return error;
            continue;
        }

        if (!prop.isWritable())
            continue;

        QVariant value;
        if (!convertJsonValue(prop.metaType(), jsonValue, value)) {
            return QStringLiteral("Invalid value for option '%1' (expected %2)")
                .arg(propertyPath(key), QString::fromUtf8(prop.metaType().name()));
        }

        const auto validationError = validatePropertyValue(key, value);
        if (!validationError.isEmpty())
            return validationError;
    }

    return {};
}

void ConfigObject::loadFromJson(const QJsonObject& obj) {
    const auto* meta = metaObject();

    qCDebug(lcConfig) << "Loading JSON into" << meta->className() << "with" << obj.keys().size()
                      << "keys:" << obj.keys();

    for (int i = basePropertyOffset(); i < meta->propertyCount(); ++i) {
        auto prop = meta->property(i);
        const auto key = QString::fromUtf8(prop.name());

        if (!obj.contains(key))
            continue;

        if (isGlobalOnly(key)) {
            qCWarning(lcConfig, "Option '%s' is global-only and will be ignored in per-monitor config",
                qUtf8Printable(propertyPath(key)));
            continue;
        }

        const auto jsonVal = obj.value(key);

        // Recurse into sub-objects
        auto current = prop.read(this);
        auto* subObj = current.value<ConfigObject*>();

        if (subObj) {
            if (!jsonVal.isObject()) {
                qCWarning(lcConfig, "Option '%s' must be a JSON object", qUtf8Printable(propertyPath(key)));
                continue;
            }
            qCDebug(lcConfig) << "  Recursing into sub-object" << key;
            subObj->loadFromJson(jsonVal.toObject());
            continue;
        }

        // Skip read-only properties
        if (!prop.isWritable())
            continue;

        QVariant value;
        if (!convertJsonValue(prop.metaType(), jsonVal, value) || !prop.write(this, value)) {
            qCWarning(lcConfig, "Invalid value for option '%s' (expected %s)", qUtf8Printable(propertyPath(key)),
                prop.metaType().name());
            continue;
        }
        m_loadedKeys.insert(key);
        qCDebug(lcConfig) << "  Loaded" << key << "=" << value;
    }
}

QJsonObject ConfigObject::toJsonObject() const {
    QJsonObject obj;
    const auto* meta = metaObject();

    for (int i = basePropertyOffset(); i < meta->propertyCount(); ++i) {
        const auto prop = meta->property(i);

        if (!prop.isReadable())
            continue;

        const auto key = QString::fromUtf8(prop.name());

        if (isGlobalOnly(key))
            continue;

        const auto value = prop.read(this);

        // Recurse into sub-objects — include only if they have loaded keys
        if (value.canView<ConfigObject*>()) {
            auto* const subObj = value.value<ConfigObject*>();
            if (subObj) {
                auto subJson = subObj->toJsonObject();
                if (!subJson.isEmpty())
                    obj.insert(key, subJson);
            }
            continue;
        }

        // Only include properties that were explicitly loaded
        if (!m_loadedKeys.contains(key))
            continue;

        if (!prop.isWritable())
            continue;

        if (prop.metaType().id() == QMetaType::QStringList) {
            QJsonArray arr;
            const auto strList = value.toStringList();
            for (const auto& s : strList)
                arr.append(s);
            obj.insert(key, arr);
            continue;
        }

        if (prop.metaType().id() == QMetaType::QVariantList) {
            obj.insert(key, QJsonArray::fromVariantList(value.toList()));
            continue;
        }

        if (prop.metaType().id() == QMetaType::QVariantMap) {
            obj.insert(key, QJsonObject::fromVariantMap(value.toMap()));
            continue;
        }

        if (prop.metaType().id() == QMetaType::fromType<QList<qreal>>().id()) {
            QJsonArray arr;
            const auto numbers = value.value<QList<qreal>>();
            for (const auto number : numbers)
                arr.append(number);
            obj.insert(key, arr);
            continue;
        }

        obj.insert(key, QJsonValue::fromVariant(value));
    }

    return obj;
}

void ConfigObject::clearLoadedKeys() {
    m_loadedKeys.clear();

    const auto* meta = metaObject();
    for (int i = basePropertyOffset(); i < meta->propertyCount(); ++i) {
        auto prop = meta->property(i);
        auto value = prop.read(this);
        auto* subObj = value.value<ConfigObject*>();
        if (subObj)
            subObj->clearLoadedKeys();
    }
}

void ConfigObject::setDefaultSource(ConfigObject* defaults) {
    m_defaults = defaults;
    if (!defaults)
        return;

    const auto* meta = metaObject();
    for (int i = basePropertyOffset(); i < meta->propertyCount(); ++i) {
        const auto prop = meta->property(i);
        auto* subObj = prop.read(this).value<ConfigObject*>();
        auto* defaultSubObj = prop.read(defaults).value<ConfigObject*>();
        if (subObj && defaultSubObj)
            subObj->setDefaultSource(defaultSubObj);
    }
}

void ConfigObject::restoreUnloadedValues() {
    auto* const fallback = m_global ? m_global : m_defaults;

    const auto* meta = metaObject();
    for (int i = basePropertyOffset(); i < meta->propertyCount(); ++i) {
        const auto prop = meta->property(i);
        const auto key = QString::fromUtf8(prop.name());
        auto* subObj = prop.read(this).value<ConfigObject*>();

        if (subObj) {
            subObj->restoreUnloadedValues();
            continue;
        }

        if (!fallback || !prop.isWritable() || m_loadedKeys.contains(key))
            continue;

        const auto previous = prop.read(this);
        if (!writeInheritedProperty(prop, prop.read(fallback))) {
            qCWarning(lcConfig, "Unable to restore option '%s'", qUtf8Printable(propertyPath(key)));
            continue;
        }
        const auto restored = prop.read(this);
        if (previous != restored)
            notifyPropertyChanged(key, restored);
        // Inherited/default values are never persisted as explicit overrides.
    }
}

void ConfigObject::flushPendingChanges() {
    const auto* meta = metaObject();
    for (int i = basePropertyOffset(); i < meta->propertyCount(); ++i) {
        auto* subObj = meta->property(i).read(this).value<ConfigObject*>();
        if (subObj)
            subObj->flushPendingChanges();
    }

    if (m_batchTimer)
        m_batchTimer->stop();
    emitBatchedChanges();
}

void ConfigObject::syncFromGlobal(ConfigObject* global) {
    m_global = global;

    const auto* meta = metaObject();
    qCDebug(lcConfig) << "Syncing" << meta->className() << "from global, loaded keys:" << m_loadedKeys;

    // Connect batched change signal (single connection per ConfigObject pair)
    connect(global, &ConfigObject::propertiesChanged, this, &ConfigObject::onGlobalPropertiesChanged);

    // Initial sync: copy all non-loaded property values from global
    for (int i = basePropertyOffset(); i < meta->propertyCount(); ++i) {
        auto prop = meta->property(i);
        const auto key = QString::fromUtf8(prop.name());

        auto current = prop.read(this);
        auto* subObj = current.value<ConfigObject*>();

        if (subObj) {
            auto globalVal = prop.read(global);
            auto* globalSub = globalVal.value<ConfigObject*>();
            if (globalSub)
                subObj->syncFromGlobal(globalSub);
            continue;
        }

        if (!prop.isWritable())
            continue;

        if (!m_loadedKeys.contains(key)) {
            auto val = prop.read(global);
            writeInheritedProperty(prop, val);
            qCDebug(lcConfig) << "  Synced" << key << "=" << val << "from global";
        } else {
            qCDebug(lcConfig) << "  Keeping loaded" << key << "=" << prop.read(this);
        }
    }
}

void ConfigObject::resyncFromGlobal() {
    if (!m_global)
        return;

    const auto* meta = metaObject();
    for (int i = basePropertyOffset(); i < meta->propertyCount(); ++i) {
        auto prop = meta->property(i);
        const auto key = QString::fromUtf8(prop.name());

        auto current = prop.read(this);
        auto* subObj = current.value<ConfigObject*>();

        if (subObj) {
            subObj->resyncFromGlobal();
            continue;
        }

        if (!prop.isWritable())
            continue;

        if (!m_loadedKeys.contains(key)) {
            writeInheritedProperty(prop, prop.read(m_global));
        }
    }
}

int ConfigObject::basePropertyOffset() {
    return ConfigObject::staticMetaObject.propertyCount();
}

QString ConfigObject::propertyPath(const QString& name) const {
    QStringList parts;
    parts.append(name);

    const QObject* obj = this;
    while (auto* parentObj = obj->parent()) {
        auto* parentConfig = qobject_cast<const ConfigObject*>(parentObj);
        if (!parentConfig)
            break;

        // Find which property name this child is on the parent
        const auto* meta = parentConfig->metaObject();
        bool found = false;
        for (int i = basePropertyOffset(); i < meta->propertyCount(); ++i) {
            auto prop = meta->property(i);
            auto val = prop.read(parentObj);
            if (val.value<QObject*>() == obj) {
                parts.prepend(QString::fromUtf8(prop.name()));
                found = true;
                break;
            }
        }

        if (!found)
            break;

        obj = parentObj;
    }

    return parts.join(QLatin1Char('.'));
}

bool ConfigObject::isPropertyLoaded(const QString& name) const {
    return m_loadedKeys.contains(name);
}

bool ConfigObject::isOverlay() const {
    return m_global != nullptr;
}

bool ConfigObject::isApplyingInheritedValue() const {
    return m_applyingInheritedValue;
}

bool ConfigObject::isGlobalOnly(const QString& name) const {
    return isOverlay() && m_globalOnlyKeys.contains(name);
}

void ConfigObject::markPropertyLoaded(const QString& name) {
    m_loadedKeys.insert(name);
}

void ConfigObject::resetOption(const QString& name) {
    const bool wasLoaded = m_loadedKeys.remove(name);
    int idx = metaObject()->indexOfProperty(name.toUtf8().constData());
    if (idx < 0)
        return;

    const auto prop = metaObject()->property(idx);
    if (!prop.isWritable())
        return;

    // Re-copy the inherited value for overlays or the compile-time default for roots.
    auto* const fallback = m_global ? m_global : m_defaults;
    if (fallback) {
        writeInheritedProperty(prop, prop.read(fallback));
        m_loadedKeys.remove(name);
    }

    // Removing an explicit key is a persistence change even when its effective
    // value was already identical to the inherited/default value.
    if (wasLoaded)
        notifyPropertyChanged(name, prop.read(this));
}

void ConfigObject::onGlobalPropertiesChanged(const QMap<QString, QVariant>& changed) {
    for (auto it = changed.begin(); it != changed.end(); ++it) {
        if (m_loadedKeys.contains(it.key()))
            continue;

        int idx = metaObject()->indexOfProperty(it.key().toUtf8().constData());
        if (idx >= 0) {
            writeInheritedProperty(metaObject()->property(idx), it.value());
            qCDebug(lcConfig) << metaObject()->className() << "synced" << it.key() << "=" << it.value()
                              << "from global change";
        }
    }
}

void ConfigObject::markGlobalOnly(const QString& name) {
    m_globalOnlyKeys.insert(name);
}

bool ConfigObject::writeInheritedProperty(const QMetaProperty& property, const QVariant& value) {
    QScopedValueRollback guard(m_applyingInheritedValue, true);
    return property.write(this, value);
}

void ConfigObject::notifyPropertyChanged(const QString& name, const QVariant& value) {
    m_pendingChanges.insert(name, value);

    if (!m_batchTimer) {
        m_batchTimer = new QTimer(this);
        m_batchTimer->setSingleShot(true);
        m_batchTimer->setInterval(0);
        connect(m_batchTimer, &QTimer::timeout, this, &ConfigObject::emitBatchedChanges);
    }

    m_batchTimer->start();
}

void ConfigObject::emitBatchedChanges() {
    if (m_pendingChanges.isEmpty())
        return;

    auto changes = std::move(m_pendingChanges);
    m_pendingChanges.clear();
    emit propertiesChanged(changes);
}

} // namespace caelestia::config
