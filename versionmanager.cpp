#include "versionmanager.h"

#include <QTextStream>
#include <QStandardPaths>
#include <QDir>
#include <QSettings>

VersionManager::VersionManager() : m_versionList(m_versions) {
    baseDir = QDir(QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)).filePath("mcpelauncher/versions");
    QDir().mkpath(baseDir);
    loadVersions();
}

void VersionManager::loadVersions() {
    QSettings settings(QDir(baseDir).filePath("versions.ini"), QSettings::IniFormat);
    for (QString group : settings.childGroups()) {
        settings.beginGroup(group);
        int versionCode = settings.value("versionCode").toInt();
        VersionInfo& ver = m_versions[versionCode];
        ver.directory = group;
        ver.versionName = settings.value("versionName").toString();
        ver.versionCode = versionCode;
        settings.endGroup();
    }
}

void VersionManager::saveVersions() {
    QSettings settings(QDir(baseDir).filePath("versions.ini"), QSettings::IniFormat);
    for (auto const& ver : m_versions) {
        settings.beginGroup(ver.directory);
        settings.setValue("versionName", ver.versionName);
        settings.setValue("versionCode", ver.versionCode);
        settings.endGroup();
    }
    settings.sync();
}

QString VersionManager::getTempTemplate() {
    return QDir(getBaseDir()).filePath("temp-XXXXXX");
}

QString VersionManager::getDirectoryFor(std::string const& versionName) {
    return QDir(getBaseDir()).filePath(QString::fromStdString(versionName));
}

void VersionManager::addVersion(QString directory, QString versionName, int versionCode) {
    VersionInfo& ver = m_versions[versionCode];
    ver.directory = directory;
    ver.versionName = directory;
    ver.versionCode = versionCode;
    saveVersions();
    emit versionListChanged();
}

VersionInfo* VersionList::latestDownloadedVersion() const {
    if (m_versions.empty())
        return nullptr;
    return &(m_versions.end() - 1).value();
}
