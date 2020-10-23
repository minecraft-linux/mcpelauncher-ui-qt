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

#include "supportedandroidabis.h"

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
        for (auto &&abi : SupportedAndroidAbis::getAbis()) {
            if (QFile(getDirectoryFor(ver->directory) + "/lib/" + QString::fromStdString(abi.first) + "/libminecraftpe.so").exists()) {
                ver->archs.append(QString::fromStdString(abi.first));
            }
        }
        
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

QString VersionManager::getDirectoryFor(QString const& directory) {
    return QDir(getBaseDir()).filePath(directory);
}

QString VersionManager::getDirectoryFor(std::string const& directory) {
    return getDirectoryFor(QString::fromStdString(directory));
}

QString VersionManager::getDirectoryFor(VersionInfo *version) {
    if (version == nullptr)
        return QString();
    return getDirectoryFor(version->directory);
}

void VersionManager::addVersion(QString directory, QString versionName, int versionCode) {
    auto& ver = m_versions[versionCode];
    if (ver == nullptr)
        ver = new VersionInfo(this);
    ver->directory = directory;
    ver->versionName = versionName;
    ver->versionCode = versionCode;
    for (auto &&abi : SupportedAndroidAbis::getAbis()) {
        if (QFile(getDirectoryFor(ver->directory) + "/lib/" + QString::fromStdString(abi.first) + "/libminecraftpe.so").exists()) {
            ver->archs.append(QString::fromStdString(abi.first));
        }
    }
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

void VersionManager::removeVersion(VersionInfo* version, QStringList abis) {
    auto val = m_versions.find(version->versionCode);
    if (val.value() != version)
        return;
    for (auto&& abi : abis) {
        QDir(getDirectoryFor(version) + "/lib/" + abi).removeRecursively();;
    }
    m_versions.erase(val);
    saveVersions();
    emit versionListChanged();
}

bool VersionManager::checkSupport(VersionInfo* version) {
    if(!version) return false;
    return checkSupport(version->directory);
}

bool VersionManager::checkSupport(QString const& directory) {
    for (auto &&abi : SupportedAndroidAbis::getAbis()) {
        if (abi.second.compatible && QFile(getDirectoryFor(directory) + "/lib/" + QString::fromStdString(abi.first) + "/libminecraftpe.so").exists()) {
            return true;
        }
    }
    return false;
}

VersionInfo* VersionList::latestDownloadedVersion() const {
    if (m_versions.empty())
        return nullptr;
    return (m_versions.end() - 1).value();
}
