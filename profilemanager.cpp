#include "profilemanager.h"

#include <QDir>
#include <QStandardPaths>

ProfileManager::ProfileManager(QObject *parent) : QObject(parent) {
    m_baseDir = QDir(QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)).filePath("mcpelauncher/profiles");
    QDir().mkpath(m_baseDir);

    m_defaultProfile = new ProfileInfo(this);
    m_defaultProfile->name = "Default";
    m_defaultProfile->nameLocked = true;
    m_profiles.push_back(m_defaultProfile);

    m_settings.reset(new QSettings(QDir(m_baseDir).filePath("profiles.ini"), QSettings::IniFormat));
    loadProfiles();
}

ProfileInfo* ProfileManager::createProfile(QString name) {
    ProfileInfo* ret = new ProfileInfo(this);
    ret->name = std::move(name);
    m_profiles.push_back(ret);
    emit profilesChanged();
    return ret;
}

void ProfileManager::deleteProfile(ProfileInfo *profile) {
    m_profiles.removeOne(profile);
    emit profilesChanged();
}

void ProfileManager::loadProfiles() {
    auto& settings = this->settings();
    for (QString const& group : settings.childGroups()) {
        settings.beginGroup(group);
        ProfileInfo* profile;
        if (group == "Default") {
            profile = defaultProfile();
        } else {
            profile = new ProfileInfo(this);
            m_profiles.push_back(profile);
        }
        if (!profile->nameLocked)
            profile->name = group;
        QString version = settings.value("version").toString();
        if (version == "googleplay") {
            profile->versionType = ProfileInfo::VersionType::LATEST_GOOGLE_PLAY;
        } else if (version.startsWith("lock ")) {
            profile->versionType = ProfileInfo::VersionType::LOCKED;
            profile->versionDirName = version.right(version.length() - 5);
        }
        profile->windowCustomSize = settings.value("windowCustomSize").toBool();
        profile->windowWidth = settings.value("windowWidth").toInt();
        profile->windowHeight = settings.value("windowHeight").toInt();
        settings.endGroup();
    }
}

ProfileInfo::ProfileInfo(ProfileManager* pm) : QObject(pm), manager(pm) {
}

void ProfileInfo::save() {
    auto& settings = manager->settings();
    settings.beginGroup(name);
    if (versionType == VersionType::LATEST_GOOGLE_PLAY) {
        settings.setValue("version", "googleplay");
    } else if (versionType == VersionType::LOCKED) {
        settings.setValue("version", "lock " + versionDirName);
    }
    settings.setValue("windowCustomSize", windowCustomSize);
    settings.setValue("windowWidth", windowWidth);
    settings.setValue("windowHeight", windowHeight);
    settings.endGroup();
}

void ProfileInfo::setName(const QString &newName) {
    if (name == newName)
        return;
    auto& settings = manager->settings();
    settings.remove(name);
    this->name = newName;
    save();
    emit manager->profilesChanged();
}
