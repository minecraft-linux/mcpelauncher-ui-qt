#include "profilemanager.h"

ProfileManager::ProfileManager(QObject *parent) : QObject(parent) {
    m_defaultProfile = new ProfileInfo(this);
    m_defaultProfile->name = "Default";
    m_profiles.push_back(m_defaultProfile);
}
