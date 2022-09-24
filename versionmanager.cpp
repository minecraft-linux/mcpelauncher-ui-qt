#include "versionmanager.h"

#include <QTextStream>
#include <QStandardPaths>
#include <QDir>
#include <QSettings>

#ifndef LAUNCHER_VERSIONDB_URL
#define LAUNCHER_VERSIONDB_URL "https://raw.githubusercontent.com/minecraft-linux/mcpelauncher-versiondb/master"
#endif

VersionManager::VersionManager() : m_versionList(m_versions), m_archival(LAUNCHER_VERSIONDB_URL) {
    baseDir = QDir(QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)).filePath("mcpelauncher/versions");
    QDir().mkpath(baseDir);
    loadVersions();
}

#include "supportedandroidabis.h"

void VersionManager::loadVersions() {
    QSettings settings(QDir(baseDir).filePath("versions.ini"), QSettings::IniFormat);
    for (QString const& group : settings.childGroups()) {
        settings.beginGroup(group);
        int size = settings.beginReadArray("codes");
        if (size >= 1) {
            auto ver = new VersionInfo(this);
            int i = 0;
            while (i < size) {
                settings.setArrayIndex(i++);
                auto versionCode = settings.value("code").toInt();
                ver->codes.insert(settings.value("arch").toString(), versionCode);
                m_versions[versionCode] = ver;
            }
            settings.endArray();
            ver->directory = group;
            ver->versionName = settings.value("versionName").toString();
        } else {
            settings.endArray();
            // Migrate previous format
            bool ok = false;
            int versionCode = settings.value("versionCode").toInt(&ok);
            if (ok) {
                auto& ver = m_versions[versionCode];
                if (ver == nullptr)
                    ver = new VersionInfo(this);
                ver->directory = group;
                ver->versionName = settings.value("versionName").toString();
                for (auto &&abi : SupportedAndroidAbis::getAbis()) {
                    if (QFile(getDirectoryFor(ver->directory) + "/lib/" + QString::fromStdString(abi.first) + "/libminecraftpe.so").exists()) {
                        ver->codes[QString::fromStdString(abi.first)] = versionCode;
                    }
                }
            }
        }
        
        settings.endGroup();
    }
}

void VersionManager::saveVersions() {
    QSettings settings(QDir(baseDir).filePath("versions.ini"), QSettings::IniFormat);
    settings.clear();
    // TODO skip writeing duplicates, e.g. one game version has multiple versionscode's
    for (auto const& ver : m_versions) {
        settings.beginGroup(ver->directory);
        int i = 0;
        settings.setValue("versionName", ver->versionName);
        settings.setValue("versionCode", ver->versionCode());
        auto size = ver->codes.size();
        settings.beginWriteArray("codes", size);
        QHash<QString, int>::const_iterator it = ver->codes.constBegin();
        while (it != ver->codes.constEnd()) {
            settings.setArrayIndex(i++);
            settings.setValue("code", it.value());
            settings.setValue("arch", it.key());
            ++it;
        }
        settings.endArray();
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
    if (ver == nullptr) {
        for (auto const& ver2 : m_versions) {
            // Find existing entry
            if (ver2 && directory == ver2->directory) {
                ver = ver2;
                break;
            }
        }
        // Fallback old behavior
        if (ver == nullptr) {
            ver = new VersionInfo(this);
        }
    }
    ver->directory = directory;
    ver->versionName = versionName;
    for (auto &&abi : SupportedAndroidAbis::getAbis()) {
        auto && it = ver->codes.constFind(QString::fromStdString(abi.first));
        if (it == ver->codes.constEnd() && QFile(getDirectoryFor(ver->directory) + "/lib/" + QString::fromStdString(abi.first) + "/libminecraftpe.so").exists()) {
            ver->codes[QString::fromStdString(abi.first)] = versionCode;
        }
    }
    saveVersions();
    emit versionListChanged();
}

void VersionManager::removeVersion(VersionInfo* version) {
    if (!version) return;
    for (auto && versionCode : version->codes) {
        auto val = m_versions.find(versionCode);
        if (val.value() != version)
            return;
        QDir(getDirectoryFor(version)).removeRecursively();
        m_versions.erase(val);
    }
    saveVersions();
    emit versionListChanged();
}

void VersionManager::removeVersion(VersionInfo* version, QStringList abis) {
    if (!version) return;
    for (auto&& abi : abis) {
        auto && versionCode = version->codes.constFind(abi);
        if (versionCode != version->codes.constEnd()) {
            auto val = m_versions.find(versionCode.value());
            if (val.value() != version)
                continue;

            m_versions.erase(val);
        }
    }
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
    return m_versions.last();
}
