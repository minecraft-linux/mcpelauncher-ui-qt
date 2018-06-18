#include "googleversionchannel.h"
#include "googleplayapi.h"

GoogleVersionChannel::GoogleVersionChannel() {
    m_settings.beginGroup("googleversionchannel");
    m_latestVersion = m_settings.value("latest_version").toString();
    m_latestVersionCode = m_settings.value("latest_version_code").toInt();
}

void GoogleVersionChannel::setPlayApi(GooglePlayApi *value) {
    Q_ASSERT(m_playApi == nullptr);
    m_playApi = value;
    connect(value, &GooglePlayApi::ready, this, &GoogleVersionChannel::onApiReady);
    connect(value, &GooglePlayApi::appInfoReceived, this, &GoogleVersionChannel::onAppInfoReceived);
}

void GoogleVersionChannel::onApiReady() {
    m_playApi->requestAppInfo("com.mojang.minecraftpe");
}

void GoogleVersionChannel::onAppInfoReceived(const QString &packageName, const QString &version, int versionCode) {
    if (packageName == "com.mojang.minecraftpe") {
        m_latestVersion = version;
        m_latestVersionCode = versionCode;
        m_settings.setValue("latest_version", m_latestVersion);
        m_settings.setValue("latest_version_code", m_latestVersionCode);
        emit latestVersionChanged();
    }
}
