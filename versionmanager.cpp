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
    for (QString const& group : settings.childGroups()) {
        settings.beginGroup(group);
        int versionCode = settings.value("versionCode").toInt();
        auto& ver = m_versions[versionCode];
        if (ver == nullptr)
            ver = new VersionInfo(this);
        ver->directory = group;
        ver->versionName = settings.value("versionName").toString();
        ver->versionCode = versionCode;
        settings.endGroup();
    }
}

void VersionManager::saveVersions() {
    QSettings settings(QDir(baseDir).filePath("versions.ini"), QSettings::IniFormat);
    settings.clear();
    for (auto const& ver : m_versions) {
        settings.beginGroup(ver->directory);
        settings.setValue("versionName", ver->versionName);
        settings.setValue("versionCode", ver->versionCode);
        settings.endGroup();
    }
    settings.sync();
}

QString VersionManager::getTempTemplate() {
    return QDir(getBaseDir()).filePath("temp-XXXXXX");
}

QString VersionManager::getDirectoryFor(QString const& versionName) {
    return QDir(getBaseDir()).filePath(versionName);
}

QString VersionManager::getDirectoryFor(std::string const& versionName) {
    return getDirectoryFor(QString::fromStdString(versionName));
}

QString VersionManager::getDirectoryFor(VersionInfo *version) {
    if (version == nullptr)
        return QString();
    return getDirectoryFor(version->versionName);
}

void VersionManager::addVersion(QString directory, QString versionName, int versionCode) {
    auto& ver = m_versions[versionCode];
    if (ver == nullptr)
        ver = new VersionInfo(this);
    ver->directory = directory;
    ver->versionName = versionName;
    ver->versionCode = versionCode;
    saveVersions();
    emit versionListChanged();
}

void VersionManager::removeVersion(VersionInfo* version) {
    auto val = m_versions.find(version->versionCode);
    if (val.value() != version)
        return;
    QDir(getDirectoryFor(version)).removeRecursively();
    m_versions.erase(val);
    saveVersions();
    emit versionListChanged();
}

VersionInfo* VersionList::latestDownloadedVersion() const {
    if (m_versions.empty())
        return nullptr;
    return (m_versions.end() - 1).value();
}
