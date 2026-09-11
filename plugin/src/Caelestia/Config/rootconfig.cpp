#include "rootconfig.hpp"

#include <cmath>
#include <limits>
#include <qcryptographichash.h>
#include <qdatetime.h>
#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qjsondocument.h>
#include <qmetaobject.h>
#include <qsavefile.h>
#include <qstandardpaths.h>

namespace caelestia::config {

namespace {

QString watchRoot() {
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation);
}

QString dataSignature(const QByteArray& data) {
    return QStringLiteral("sha256:%1")
        .arg(QString::fromLatin1(QCryptographicHash::hash(data, QCryptographicHash::Sha256).toHex()));
}

} // namespace

RootConfig::RootConfig(QObject* parent)
    : ConfigObject(parent) {}

bool RootConfig::recentlySaved() const {
    return m_recentlySaved;
}

QStringList RootConfig::collectUnknownKeys(const ConfigObject* obj, const QJsonObject& json) {
    QStringList unknown;
    const auto* meta = obj->metaObject();

    QSet<QString> known;
    for (int i = ConfigObject::basePropertyOffset(); i < meta->propertyCount(); ++i)
        known.insert(QString::fromUtf8(meta->property(i).name()));
    if (qobject_cast<const RootConfig*>(obj))
        known.insert(QStringLiteral("configVersion"));

    for (auto it = json.begin(); it != json.end(); ++it) {
        if (!known.contains(it.key())) {
            unknown.append(it.key());
        } else if (it.value().isObject()) {
            int idx = meta->indexOfProperty(it.key().toUtf8().constData());
            if (idx >= 0) {
                auto prop = meta->property(idx);
                auto value = prop.read(obj);
                auto* subObj = value.value<ConfigObject*>();
                if (subObj) {
                    const auto subUnknown = collectUnknownKeys(subObj, it.value().toObject());
                    for (const auto& subKey : subUnknown)
                        unknown.append(it.key() + QStringLiteral(".") + subKey);
                }
            }
        }
    }

    return unknown;
}

QJsonObject RootConfig::mergePreservingUnknown(
    const ConfigObject* obj, const QJsonObject& original, const QJsonObject& serialized) {
    auto merged = original;
    const auto* meta = obj->metaObject();

    for (int i = ConfigObject::basePropertyOffset(); i < meta->propertyCount(); ++i) {
        const auto prop = meta->property(i);
        const auto key = QString::fromUtf8(prop.name());
        auto* const subObj = prop.read(obj).value<ConfigObject*>();

        if (subObj) {
            const auto subOriginal = original.value(key).toObject();
            const auto subSerialized = serialized.value(key).toObject();
            const auto subMerged = mergePreservingUnknown(subObj, subOriginal, subSerialized);
            if (subMerged.isEmpty())
                merged.remove(key);
            else
                merged.insert(key, subMerged);
        } else if (serialized.contains(key)) {
            merged.insert(key, serialized.value(key));
        } else {
            // Known options omitted by serialization were reset and must be removed.
            merged.remove(key);
        }
    }

    return merged;
}

void RootConfig::setupFileBackend(const QString& path, const QString& screen) {
    m_filePath = path;
    m_screen = screen;

    m_watcher = new QFileSystemWatcher(this);
    m_saveTimer = new QTimer(this);
    m_cooldownTimer = new QTimer(this);
    m_retryTimer = new QTimer(this);

    m_retryTimer->setSingleShot(true);
    m_retryTimer->setInterval(50);
    connect(m_retryTimer, &QTimer::timeout, this, &RootConfig::reload);

    m_saveTimer->setSingleShot(true);
    m_saveTimer->setInterval(500);
    connect(m_saveTimer, &QTimer::timeout, this, [this] {
        QDir().mkpath(QFileInfo(m_filePath).absolutePath());

        QJsonObject sourceJson;
        QString expectedSignature;
        if (QFile::exists(m_filePath)) {
            QFile sourceFile(m_filePath);
            if (!sourceFile.open(QIODevice::ReadOnly)) {
                const auto err = QStringLiteral("Failed to read %1 before saving: %2")
                                     .arg(m_filePath, sourceFile.errorString());
                qCWarning(lcConfig, "%s", qUtf8Printable(err));
                emit saveFailed(err, m_screen);
                return;
            }

            const auto sourceData = sourceFile.readAll();
            expectedSignature = dataSignature(sourceData);

            // Never treat an edit made since our last successful load/save as the
            // new baseline. Doing so would overwrite known keys with stale values.
            if (expectedSignature != m_lastSignature) {
                const auto err = QStringLiteral("Config changed externally before saving: %1").arg(m_filePath);
                qCWarning(lcConfig, "%s", qUtf8Printable(err));
                emit saveFailed(err, m_screen);
                m_reloadDebounce->start();
                return;
            }

            QJsonParseError parseError{};
            const auto sourceDoc = QJsonDocument::fromJson(sourceData, &parseError);
            if (parseError.error != QJsonParseError::NoError || !sourceDoc.isObject()) {
                const auto detail = parseError.error == QJsonParseError::NoError
                    ? QStringLiteral("top-level JSON value must be an object")
                    : parseError.errorString();
                const auto err = QStringLiteral("Refusing to overwrite invalid config %1: %2").arg(m_filePath, detail);
                qCWarning(lcConfig, "%s", qUtf8Printable(err));
                emit saveFailed(err, m_screen);
                return;
            }
            sourceJson = sourceDoc.object();

            // The file may have changed while it was being read and parsed.
            if (fileSignature() != expectedSignature) {
                const auto err = QStringLiteral("Config changed while preparing to save: %1").arg(m_filePath);
                qCWarning(lcConfig, "%s", qUtf8Printable(err));
                emit saveFailed(err, m_screen);
                m_reloadDebounce->start();
                return;
            }
        } else if (!m_lastSignature.isEmpty()) {
            const auto err = QStringLiteral("Config was removed externally before saving: %1").arg(m_filePath);
            qCWarning(lcConfig, "%s", qUtf8Printable(err));
            emit saveFailed(err, m_screen);
            m_reloadDebounce->start();
            return;
        }

        QSaveFile file(m_filePath);
        if (!file.open(QIODevice::WriteOnly)) {
            auto err = QStringLiteral("Failed to write %1: %2").arg(m_filePath, file.errorString());
            qCWarning(lcConfig, "%s", qUtf8Printable(err));
            emit saveFailed(err, m_screen);
            return;
        }

        auto json = mergePreservingUnknown(this, sourceJson, toJsonObject());
        if (const auto version = currentConfigVersion(); version > 0)
            json.insert(QStringLiteral("configVersion"), version);
        const auto data = QJsonDocument(json).toJson(QJsonDocument::Indented);
        const auto savedSignature = dataSignature(data);
        if (file.write(data) != data.size()) {
            auto err = QStringLiteral("Failed to write %1: %2").arg(m_filePath, file.errorString());
            qCWarning(lcConfig, "%s", qUtf8Printable(err));
            file.cancelWriting();
            emit saveFailed(err, m_screen);
            return;
        }

        // Do not replace a file that was externally changed after our snapshot.
        if (fileSignature() != expectedSignature) {
            const auto err = QStringLiteral("Config changed while saving: %1").arg(m_filePath);
            qCWarning(lcConfig, "%s", qUtf8Printable(err));
            file.cancelWriting();
            emit saveFailed(err, m_screen);
            m_reloadDebounce->start();
            return;
        }

        if (!file.commit()) {
            auto err = QStringLiteral("Failed to commit %1: %2").arg(m_filePath, file.errorString());
            qCWarning(lcConfig, "%s", qUtf8Printable(err));
            file.cancelWriting();
            emit saveFailed(err, m_screen);
            return;
        }
        // Update watches — save may have created directories
        updateWatch();
        // The baseline is the content we committed, not a later reread that
        // could already contain an external writer's replacement.
        m_lastSignature = savedSignature;
        if (fileSignature() != savedSignature)
            m_reloadDebounce->start();

        emit saved(m_screen);
    });

    m_cooldownTimer->setSingleShot(true);
    m_cooldownTimer->setInterval(2000);
    connect(m_cooldownTimer, &QTimer::timeout, this, [this] {
        m_recentlySaved = false;
    });

    m_reloadDebounce = new QTimer(this);
    m_reloadDebounce->setSingleShot(true);
    m_reloadDebounce->setInterval(50);
    connect(m_reloadDebounce, &QTimer::timeout, this, &RootConfig::reload);

    // Auto-save when any property changes (debounced by the save timer)
    connectAutoSave(this);

    connect(m_watcher, &QFileSystemWatcher::directoryChanged, this, &RootConfig::onWatcherEvent);
    connect(m_watcher, &QFileSystemWatcher::fileChanged, this, &RootConfig::onWatcherEvent);

    qCDebug(lcConfig) << "Setting up file backend for" << metaObject()->className() << "at" << path;

    updateWatch();

    // Load immediately so values are available during construction.
    // Defer signal emissions to next event loop tick so QML has time to connect.
    auto result = reloadFromFile();
    QTimer::singleShot(0, this, [this, result] {
        emitLoadSignals(result, false);
    });
}

void RootConfig::connectAutoSave(ConfigObject* obj) {
    connect(obj, &ConfigObject::propertiesChanged, this, [this] {
        if (!m_loading)
            saveToFile();
    });

    // Recurse into sub-objects
    const auto* meta = obj->metaObject();
    for (int i = ConfigObject::basePropertyOffset(); i < meta->propertyCount(); ++i) {
        auto prop = meta->property(i);
        auto value = prop.read(obj);
        auto* subObj = value.value<ConfigObject*>();
        if (subObj)
            connectAutoSave(subObj);
    }
}

void RootConfig::updateWatch() {
    auto targetDir = QFileInfo(m_filePath).absolutePath();

    // Find the nearest existing directory, walking up toward the watch root
    auto dir = targetDir;
    while (!QFile::exists(dir) && dir != watchRoot() && !dir.isEmpty()) {
        auto parent = QFileInfo(dir).absolutePath();
        if (parent == dir)
            break; // reached filesystem root
        dir = parent;
    }

    // Update directory watch if it changed
    if (dir != m_watchedDir) {
        if (!m_watchedDir.isEmpty())
            m_watcher->removePath(m_watchedDir);

        m_watchedDir = dir;

        if (QFile::exists(dir))
            m_watcher->addPath(dir);
    }

    // Watch the file itself if it exists (for in-place modifications)
    if (QFile::exists(m_filePath)) {
        if (!m_watcher->files().contains(m_filePath))
            m_watcher->addPath(m_filePath);
    }
}

void RootConfig::onWatcherEvent() {
    // Re-evaluate what to watch — directories may have been created or deleted
    updateWatch();

    // Only reload when the file actually changed (directory is watched so events fire for unrelated files)
    if (fileSignature() == m_lastSignature)
        return;

    m_reloadDebounce->start();
}

QString RootConfig::fileSignature() const {
    QFile file(m_filePath);
    if (!file.exists())
        return QString();

    if (!file.open(QIODevice::ReadOnly)) {
        const QFileInfo info(file);
        return QStringLiteral("unreadable:%1:%2").arg(info.size()).arg(info.lastModified().toMSecsSinceEpoch());
    }

    return dataSignature(file.readAll());
}

void RootConfig::saveToFile() {
    if (!m_saveTimer)
        return;
    m_saveTimer->start();
    m_recentlySaved = true;
    m_cooldownTimer->start();
}

std::optional<QString> RootConfig::reloadFromFile() {
    // An explicit or watcher-driven reload supersedes any queued local save.
    if (m_saveTimer)
        m_saveTimer->stop();
    if (m_reloadDebounce)
        m_reloadDebounce->stop();
    if (m_retryTimer)
        m_retryTimer->stop();

    QFile file(m_filePath);

    if (!file.exists()) {
        qCDebug(lcConfig) << "File does not exist:" << m_filePath;
        m_loading = true;
        clearLoadedKeys();
        restoreUnloadedValues();
        flushPendingChanges();
        m_loading = false;
        m_lastUnknownKeys.clear();
        m_parseRetries = 0;
        m_lastSignature.clear();
        if (!fileSignature().isEmpty())
            m_reloadDebounce->start();
        return QString();
    }

    if (!file.open(QIODevice::ReadOnly)) {
        auto err = QStringLiteral("Failed to open %1: %2").arg(m_filePath, file.errorString());
        qCDebug(lcConfig, "%s", qUtf8Printable(err));
        return err;
    }

    const auto sourceData = file.readAll();
    const auto loadedSignature = dataSignature(sourceData);
    QJsonParseError error{};
    auto doc = QJsonDocument::fromJson(sourceData, &error);

    if (error.error != QJsonParseError::NoError) {
        if (m_retryTimer && m_parseRetries < 3) {
            m_parseRetries++;
            qCDebug(lcConfig, "Failed to parse %s: %s - retrying (%d/3)", qUtf8Printable(m_filePath),
                qUtf8Printable(error.errorString()), m_parseRetries);
            m_retryTimer->start();
            return std::nullopt; // pending retry — no signal
        }

        qCWarning(lcConfig, "Failed to parse %s: %s", qUtf8Printable(m_filePath), qUtf8Printable(error.errorString()));
        m_parseRetries = 0;
        return QStringLiteral("JSON parse error: %1").arg(error.errorString());
    }

    m_parseRetries = 0;

    if (!doc.isObject()) {
        const auto err = QStringLiteral("Top-level JSON value in %1 must be an object").arg(m_filePath);
        qCWarning(lcConfig, "%s", qUtf8Printable(err));
        return err;
    }

    qCDebug(lcConfig) << "Reloading" << metaObject()->className() << "from" << m_filePath;

    auto jsonObj = doc.object();
    bool migrationPending = false;
    if (const auto currentVersion = currentConfigVersion(); currentVersion > 0) {
        int sourceVersion = 0;
        if (jsonObj.contains(QStringLiteral("configVersion"))) {
            const auto versionValue = jsonObj.take(QStringLiteral("configVersion"));
            const auto versionNumber = versionValue.toDouble(std::numeric_limits<double>::quiet_NaN());
            if (!versionValue.isDouble() || !std::isfinite(versionNumber)
                || std::floor(versionNumber) < versionNumber || versionNumber < 0
                || versionNumber > std::numeric_limits<int>::max()) {
                return QStringLiteral("Option 'configVersion' must be a non-negative integer");
            }
            sourceVersion = static_cast<int>(versionNumber);
        }

        if (sourceVersion > currentVersion) {
            return QStringLiteral("Config version %1 is newer than supported version %2")
                .arg(sourceVersion)
                .arg(currentVersion);
        }

        if (sourceVersion < currentVersion) {
            const auto migrationError = migrateConfig(jsonObj, sourceVersion);
            if (!migrationError.isEmpty())
                return QStringLiteral("Config migration failed: %1").arg(migrationError);
            migrationPending = true;
        }
    }

    const auto validationError = validateJson(jsonObj);
    if (!validationError.isEmpty()) {
        qCWarning(lcConfig, "Failed to validate %s: %s", qUtf8Printable(m_filePath),
            qUtf8Printable(validationError));
        return validationError;
    }

    m_loading = true;

    clearLoadedKeys();
    restoreUnloadedValues();

    loadFromJson(jsonObj);

    // Emit aggregate change notifications while auto-save is still suppressed.
    flushPendingChanges();

    m_loading = false;
    // Collect unknown keys — caller is responsible for emitting signals
    m_lastUnknownKeys = collectUnknownKeys(this, jsonObj);
    // Invalid files must never become a save baseline. Only accept the content
    // signature after parsing, validation and loading have all succeeded.
    m_lastSignature = loadedSignature;
    if (fileSignature() != loadedSignature)
        m_reloadDebounce->start();
    else if (migrationPending)
        saveToFile();

    return QString(); // success
}

void RootConfig::save() {
    saveToFile();
}

void RootConfig::emitLoadSignals(const std::optional<QString>& result, bool emitLoaded) {
    if (!result.has_value())
        return;

    for (const auto& key : std::as_const(m_lastUnknownKeys))
        emit unknownOption(key, m_screen);
    m_lastUnknownKeys.clear();

    if (result->isEmpty()) {
        if (emitLoaded)
            emit loaded(m_screen);
    } else {
        emit loadFailed(*result, m_screen);
    }
}

void RootConfig::reload() {
    emitLoadSignals(reloadFromFile());
}

void RootConfig::setDefaults(ConfigObject* defaults) {
    setDefaultSource(defaults);
}

int RootConfig::currentConfigVersion() const {
    return 0;
}

QString RootConfig::migrateConfig(QJsonObject&, int) const {
    return {};
}

} // namespace caelestia::config
