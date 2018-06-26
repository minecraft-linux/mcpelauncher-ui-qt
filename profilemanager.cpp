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

    auto selectedProfile = m_settings->value("selected").toString();
    m_activeProfile = m_defaultProfile;
    for (ProfileInfo* profile : m_profiles) {
        if (profile->name == selectedProfile) {
            m_activeProfile = profile;
            break;
        }
    }
}

ProfileInfo* ProfileManager::createProfile(QString name) {
    ProfileInfo* ret = new ProfileInfo(this);
    ret->name = std::move(name);
    m_profiles.push_back(ret);
    emit profilesChanged();
    return ret;
}

void ProfileManager::deleteProfile(ProfileInfo *profile) {
    m_settings->remove(profile->name);
    m_profiles.removeOne(profile);
    if (m_activeProfile == profile)
        setActiveProfile(m_defaultProfile);
    emit profilesChanged();
    delete profile;
}

void ProfileManager::setActiveProfile(ProfileInfo *profile) {
    m_activeProfile = profile;
    m_settings->setValue("selected", profile->name);
    emit activeProfileChanged();
}

void ProfileManager::loadProfiles() {
    auto& settings = this->settings();
    for (QString const& group : settings.childGroups()) {
        if (group == "Metadata")
            continue;
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
        profile->dataDirCustom = settings.value("dataDirCustom").toBool();
        profile->dataDir = settings.value("dataDir").toString();
        profile->windowCustomSize = settings.value("windowCustomSize").toBool();
        profile->windowWidth = settings.value("windowWidth").toInt();
        profile->windowHeight = settings.value("windowHeight").toInt();
        profile->pixelScale = settings.value("pixelScale").toFloat();
        settings.endGroup();
    }
}

bool ProfileManager::validateName(QString const& name) {
    return (!name.contains('/'));
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
    settings.setValue("dataDirCustom", dataDirCustom);
    settings.setValue("dataDir", dataDir);
    settings.setValue("windowCustomSize", windowCustomSize);
    settings.setValue("windowWidth", windowWidth);
    settings.setValue("windowHeight", windowHeight);
    settings.setValue("pixelScale", pixelScale);
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
