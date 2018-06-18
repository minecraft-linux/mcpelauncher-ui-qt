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

QString VersionManager::getDirectoryFor(const MinecraftElfInfo &version) {
    QString versionStr;
    QTextStream stream (&versionStr, QIODevice::WriteOnly);
    stream << version.versionMajor << '.' << version.versionMinor << '.' << version.versionPatch << '.' << version.versionRevision;
    if (version.isBeta)
        stream << QStringLiteral(" (beta)");
    return QDir(getBaseDir()).filePath(versionStr);
}

QStringList VersionManager::listVersions() const {
    return QDir(getBaseDir()).entryList(QDir::Dirs | QDir::NoDotAndDotDot);
}

bool VersionManager::hasVersion(QString version) const {
    return listVersions().contains(version);
}
