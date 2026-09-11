#pragma once

#include <qjsonobject.h>
#include <qstring.h>

namespace caelestia::config {

inline constexpr int CurrentGlobalConfigVersion = 3;

struct ConfigMigrationResult {
    QJsonObject config;
    QString error;
};

[[nodiscard]] ConfigMigrationResult migrateGlobalConfig(QJsonObject config, int fromVersion);

} // namespace caelestia::config
