#include "versionmanager.h"

#include <QTextStream>
#include <QStandardPaths>
#include <QDir>

VersionManager::VersionManager() {
    baseDir = QDir(QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)).filePath("mcpelauncher/versions");
    QDir().mkpath(baseDir);
}

QString VersionManager::getTempTemplate() {
    return QDir(getBaseDir()).filePath("temp-XXXXXX");
}

QString VersionManager::getDirectoryFor(std::string const& versionName) {
    return QDir(getBaseDir()).filePath(QString::fromStdString(versionName));
}

QStringList VersionManager::listVersions() const {
    return QDir(getBaseDir()).entryList(QDir::Dirs | QDir::NoDotAndDotDot);
}

bool VersionManager::hasVersion(QString version) const {
    return listVersions().contains(version);
}
