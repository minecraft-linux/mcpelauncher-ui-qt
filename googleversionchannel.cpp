#include "googleversionchannel.h"
#include "googleplayapi.h"
#include "googleloginhelper.h"
#include "googleversionchannel.h"

GoogleVersionChannel::GoogleVersionChannel() {
    m_settings.beginGroup("googleversionchannel");
    m_latestVersion = m_settings.value("latest_version").toString();
    m_latestVersionCode = m_settings.value("latest_version_code").toInt();
    m_latestVersionIsBeta = m_settings.value("latest_version_isbeta").toBool();
}

void GoogleVersionChannel::setPlayApi(GooglePlayApi *value) {
    licenseStatus = GoogleVersionChannelLicenceStatus::NOT_READY;
    setStatus(GoogleVersionChannelStatus::NOT_READY);
    if (m_playApi != nullptr) {
        disconnect(m_playApi, &GooglePlayApi::ready, this, &GoogleVersionChannel::onApiReady);
        disconnect(m_playApi, &GooglePlayApi::appInfoReceived, this, &GoogleVersionChannel::onAppInfoReceived);
        disconnect(m_playApi, &GooglePlayApi::appInfoFailed, this, &GoogleVersionChannel::onAppInfoFailed);
    }
    m_playApi = value;
    if (value) {
        connect(value, &GooglePlayApi::statusChanged, this, &GoogleVersionChannel::onStatusChanged);
        connect(value, &GooglePlayApi::ready, this, &GoogleVersionChannel::onApiReady);
        connect(value, &GooglePlayApi::appInfoReceived, this, &GoogleVersionChannel::onAppInfoReceived);
        connect(value, &GooglePlayApi::appInfoFailed, this, &GoogleVersionChannel::onAppInfoFailed);
    }
    onStatusChanged();
}

void GoogleVersionChannel::onApiReady() {
    setStatus(GoogleVersionChannelStatus::PENDING);
    m_playApi->requestAppInfo(m_trialMode ? "com.mojang.minecrafttrialpe" : "com.mojang.minecraftpe");
}

void GoogleVersionChannel::onStatusChanged() {
    auto trialMode = m_trialMode;
    auto status = m_playApi ? m_playApi->getStatus() : GooglePlayApi::GooglePlayApiStatus::FAILED;
    if(status != GooglePlayApi::GooglePlayApiStatus::SUCCEDED) {
        setStatus(GoogleVersionChannelStatus::PENDING);
        m_hasVerifiedLicense = trialMode;
        licenseStatus = status == GooglePlayApi::GooglePlayApiStatus::FAILED ? trialMode ? GoogleVersionChannelLicenceStatus::OFFLINE : GoogleVersionChannelLicenceStatus::FAILED : GoogleVersionChannelLicenceStatus::NOT_READY;
        setStatus(status == GooglePlayApi::GooglePlayApiStatus::FAILED ? GoogleVersionChannelStatus::FAILED : GoogleVersionChannelStatus::NOT_READY);
    } else {
        onApiReady();
    }
}

void GoogleVersionChannel::onAppInfoReceived(const QString &packageName, const QString &version, int versionCode, bool isBeta) {
    auto trialMode = m_trialMode;
    auto pkgName = trialMode ? "com.mojang.minecrafttrialpe" : "com.mojang.minecraftpe";
    if (packageName == pkgName) {
        m_latestVersion = version;
        m_latestVersionCode = versionCode;
        m_latestVersionIsBeta = isBeta;
        m_settings.setValue("latest_version", m_latestVersion);
        m_settings.setValue("latest_version_code", m_latestVersionCode);
        m_settings.setValue("latest_version_isbeta", m_latestVersionIsBeta);
        emit latestVersionChanged();
        licenseStatus = GoogleVersionChannelLicenceStatus::PENDING;
        setStatus(GoogleVersionChannelStatus::SUCCEDED);
        m_playApi->validateLicense(pkgName, versionCode, [this, trialMode](bool hasVerifiedLicense) {
            if(!trialMode && m_playApi->getLogin()->isChromeOS() && !hasVerifiedLicense) {
                m_playApi->getLogin()->setChromeOS(false);
                licenseStatus = GoogleVersionChannelLicenceStatus::NOT_READY;
                setStatus(GoogleVersionChannelStatus::NOT_READY);
                return;
            }
            if(trialMode) {
                this->m_hasVerifiedLicense = true;
                licenseStatus = hasVerifiedLicense ? GoogleVersionChannelLicenceStatus::SUCCEDED : GoogleVersionChannelLicenceStatus::OFFLINE;
            } else {
                this->m_hasVerifiedLicense |= hasVerifiedLicense;
                licenseStatus = hasVerifiedLicense ? GoogleVersionChannelLicenceStatus::SUCCEDED : GoogleVersionChannelLicenceStatus::FAILED;
                m_settings.setValue("latest_version_id", hasVerifiedLicense ? (m_latestVersion + QChar((char)m_latestVersionCode) + QChar((char)m_latestVersionIsBeta)) : "");
            }
            statusChanged();
        });
    }
}

void GoogleVersionChannel::onAppInfoFailed(QString const& packageName, const QString &errorMessage) {
    auto trialMode = m_trialMode;
    auto pkgName = trialMode ? "com.mojang.minecrafttrialpe" : "com.mojang.minecraftpe";
    if(packageName == pkgName) {
        if(errorMessage.contains("401") || errorMessage.contains("403")) {
            licenseStatus = GoogleVersionChannelLicenceStatus::FAILED;
            m_hasVerifiedLicense = false;
            if(!trialMode) {
                m_settings.setValue("latest_version_id", "");
            }
        } else if(trialMode || m_settings.value("latest_version_id").toString() == (m_latestVersion + QChar((char)m_latestVersionCode) + QChar((char)m_latestVersionIsBeta))) {
            m_hasVerifiedLicense = true;
            licenseStatus = GoogleVersionChannelLicenceStatus::OFFLINE;
        }
        setStatus(GoogleVersionChannelStatus::FAILED);
    }
}
