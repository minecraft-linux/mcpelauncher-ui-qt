#include "googleloginhelper.h"

#include <googleloginwindow.h>
#include <QStandardPaths>
#include <QDir>
#include <QWindow>
#include <QtConcurrent>
#include "supportedandroidabis.h"
#include "launchersettings.h"
#include "encryption.h"

std::string GoogleLoginHelper::getTokenCachePath() {
    return QDir(QStandardPaths::writableLocation(QStandardPaths::CacheLocation)).filePath("playapi_token_cache.conf").toStdString();
}

GoogleLoginHelper::GoogleLoginHelper() : loginCache(getTokenCachePath()), login(device, loginCache) {
    unlockkey = settings.value("key").toString();
    loadAccount();
}

GoogleLoginHelper::~GoogleLoginHelper() {
    delete window;
}

void GoogleLoginHelper::loadAccount() {
    if (hasAccount) {
        return;
    }
    hasEncryptedCredentials = false;
    settings.beginGroup("googlelogin");
    if (settings.contains("identifier")) {
        Encryption enc;
        auto got = settings.value("encrypted", "true").toString().toStdString();
        if(enc.Decrypt(got, unlockkey.toStdString()) == "true") {
            currentAccount.setAccountIdentifier(QString::fromStdString(enc.Decrypt(settings.value("identifier").toString().toStdString(), unlockkey.toStdString())));
            currentAccount.setAccountUserId(QString::fromStdString(enc.Decrypt(settings.value("userId").toString().toStdString(), unlockkey.toStdString())));
            currentAccount.setAccountToken(QString::fromStdString(enc.Decrypt(settings.value("token").toString().toStdString(), unlockkey.toStdString())));
        } else if(got == "true") {
            currentAccount.setAccountIdentifier(settings.value("identifier").toString());
            currentAccount.setAccountUserId(settings.value("userId").toString());
            currentAccount.setAccountToken(settings.value("token").toString());
        } else {
            hasEncryptedCredentials = true;
        }

        hasAccount = currentAccount.isValid();
        if (hasAccount) {
            login.set_token(currentAccount.accountIdentifier().toStdString(), currentAccount.accountToken().toStdString());
        } else {
            settings.endGroup();
            return;
        }
    }
    settings.endGroup();
    loadDeviceState();
    includeIncompatible = LauncherSettings().showUnsupported();
    updateDevice();
}

void GoogleLoginHelper::loadDeviceState() {
    settings.beginGroup("device_state");
    device.generated_mac_addr = settings.value("generated_mac_addr").toString().toStdString();
    device.generated_meid = settings.value("generated_meid").toString().toStdString();
    device.generated_serial_number = settings.value("generated_serial_number").toString().toStdString();
    device.random_logging_id = settings.value("generated_serial_number").toLongLong();
    settings.endGroup();
}

void GoogleLoginHelper::saveDeviceState() {
    settings.beginGroup("device_state");
    settings.setValue("generated_mac_addr", QString::fromStdString(device.generated_mac_addr));
    settings.setValue("generated_meid", QString::fromStdString(device.generated_meid));
    settings.setValue("generated_serial_number", QString::fromStdString(device.generated_serial_number));
    settings.setValue("random_logging_id", device.random_logging_id);
    // Continue to write it for backward compatibility
    settings.beginWriteArray("native_platforms", device.config_native_platforms.size());
    for (int i = 0; i < device.config_native_platforms.size(); ++i) {
        settings.setArrayIndex(i);
        settings.setValue("platform", QString::fromStdString(device.config_native_platforms[i]));
    }
    settings.endArray();
    settings.endGroup();
}

void GoogleLoginHelper::acquireAccount(QWindow *parent) {
    if (window)
        return;
    window = new GoogleLoginWindow();
    window->setAttribute(Qt::WA_DeleteOnClose);
    window->winId();
    window->windowHandle()->setTransientParent(parent);
    window->move(parent->x() + parent->width() / 2 - window->width() / 2, parent->y() + parent->height() / 2 - window->height() / 2);
    window->show();
    connect(window, &QDialog::finished, this, &GoogleLoginHelper::onLoginFinished);
}

void GoogleLoginHelper::onLoginFinished(int code) {
    if (code == QDialog::Accepted) {
        try {
            unlockkey = window->encryptionToken();
            Encryption enc;
            if(unlockkey.isEmpty()) {
                unlockkey = QString::fromStdString(enc.RandomKey());
                settings.setValue("key", unlockkey);
            }
            loginCache.clear();
            loginCache.setKey(unlockkey.toStdString());
            login.perform_with_access_token(window->accountToken().toStdString(), window->accountIdentifier().toStdString(), true)->call();
            currentAccount.setAccountIdentifier(QString::fromStdString(login.get_email()));
            currentAccount.setAccountUserId(window->accountUserId());
            currentAccount.setAccountToken(QString::fromStdString(login.get_token()));
            hasAccount = currentAccount.isValid();
            if (hasAccount) {
                settings.beginGroup("googlelogin");
                settings.setValue("encrypted", QString::fromStdString(enc.Encrypt("true", unlockkey.toStdString())));
                settings.setValue("identifier", QString::fromStdString(enc.Encrypt(currentAccount.accountIdentifier().toStdString(), unlockkey.toStdString())));
                settings.setValue("userId", QString::fromStdString(enc.Encrypt(currentAccount.accountUserId().toStdString(), unlockkey.toStdString())));
                settings.setValue("token", QString::fromStdString(enc.Encrypt(currentAccount.accountToken().toStdString(), unlockkey.toStdString())));
                settings.endGroup();
                saveDeviceState();
                accountAcquireFinished(&currentAccount);
            } else {
                loginError("Login failed");
                accountAcquireFinished(nullptr);
            }
        } catch (const std::exception& ex) {
            loginError(ex.what());
            accountAcquireFinished(nullptr);
        }
    } else {
        accountAcquireFinished(nullptr);
    }
    emit accountInfoChanged();
    window = nullptr;
}

void GoogleLoginHelper::updateDevice() {
    device = playapi::device_info {};
    if(chromeOS) {
        const char* features[] = { "android.hardware.faketouch", "android.software.backup", "org.chromium.arc.device_management", "android.software.print", "android.software.activities_on_secondary_displays", "com.google.android.feature.PIXEL_2017_EXPERIENCE", "android.software.voice_recognizers", "android.software.picture_in_picture", "android.software.cant_save_state", "com.google.android.feature.PIXEL_2018_EXPERIENCE", "android.hardware.opengles.aep", "android.hardware.type.pc", "android.hardware.bluetooth", "com.google.android.feature.GOOGLE_BUILD", "org.chromium.arc", "android.hardware.audio.output", "android.software.verified_boot", "android.hardware.camera.front", "android.hardware.screen.portrait", "com.google.android.feature.TURBO_PRELOAD", "android.hardware.microphone", "android.software.autofill", "com.google.android.feature.PIXEL_EXPERIENCE", "android.hardware.bluetooth_le", "android.software.input_methods", "android.software.companion_device_setup", "com.google.android.feature.WELLBEING", "android.hardware.wifi.passpoint", "android.hardware.screen.landscape", "android.hardware.ram.normal", "android.software.webview", "android.hardware.camera.any", "android.hardware.location.network", "android.software.cts", "com.google.android.apps.dialer.SUPPORTED", "com.google.android.feature.GOOGLE_EXPERIENCE", "com.google.android.feature.EXCHANGE_6_2", "android.software.freeform_window_management", "android.software.midi", "android.hardware.wifi", "android.hardware.location", "org.chromium.arc.video.encode_dynamic_bitrate" };
        device.config_system_features.clear();
        for(auto && feature : features) {
            device.config_system_features.push_back({feature, 0});
        }
        const char* sharedlibs[] = { "android.test.base", "android.test.mock", "com.google.android.chromeos", "com.google.android.media.effects", "org.chromium.arc.bridge", "org.chromium.arc", "com.android.location.provider", "android.ext.shared", "javax.obex", "com.google.android.gms", "android.ext.services", "android.test.runner", "org.chromium.arc.mojom", "com.google.android.dialer.support", "com.google.android.maps", "org.apache.http.legacy", "com.android.media.remotedisplay", "com.android.mediadrm.signer" };
        device.config_system_shared_libraries.clear();
        for(auto && lib : sharedlibs) {
            device.config_system_shared_libraries.push_back(lib);
        }
    }
    device.config_native_platforms = {};
    if(!singleArch.isEmpty()) {
        device.config_native_platforms.push_back(singleArch.toStdString());
    } else {
        for (auto&& abi : SupportedAndroidAbis::getAbis()) {
            if(abi.second.compatible || includeIncompatible) {
                device.config_native_platforms.push_back(abi.first);
            }
        }
    }
    device.build_sdk_version = 36;
    emit accountInfoChanged();
}

void GoogleLoginHelper::signOut() {
    hasAccount = false;
    currentAccount.setAccountIdentifier("");
    currentAccount.setAccountUserId("");
    currentAccount.setAccountToken("");
    settings.remove("googlelogin");
    settings.remove("device_state");
    loginCache.clear();
    hasEncryptedCredentials = false;
    emit accountInfoChanged();
}

QStringList GoogleLoginHelper::getAbis(bool includeIncompatible) {
    QStringList abis;
    for (auto&& abi : SupportedAndroidAbis::getAbis()) {
        if (!includeIncompatible && !abi.second.compatible || !singleArch.isEmpty() && abi.first != singleArch.toStdString()) {
            continue;
        }
        abis.append(QString::fromStdString(abi.first));
    }
    return abis;
}

QString GoogleLoginHelper::GetSupportReport() {
    QString report;
    for (auto&& abi : SupportedAndroidAbis::getAbis()) {
        report.append(tr("<b>%1</b> is %2%3<br/>").arg(QString::fromStdString(abi.first)).arg(abi.second.compatible ? "<b><font color=\"#00cc00\">" + tr("Compatible") + "</font></b>" : "<b><font color=\"#FF0000\">" + tr("Incompatible") + "</font></b>").arg(abi.second.details.length() ? "<br/>" + QString::fromStdString(abi.second.details) : ""));
    }
    return report;
}

bool GoogleLoginHelper::hideLatest() {
    if (!hasAccount || device.config_native_platforms.empty()) {
        return true;
    }
    auto supportedabis = SupportedAndroidAbis::getAbis();
    auto res = supportedabis.find(device.config_native_platforms[0]);
    return !includeIncompatible && singleArch.isEmpty() && (res == supportedabis.end() || !res->second.compatible);
}

bool GoogleLoginHelper::isSupported() {
    for (auto &&abi : SupportedAndroidAbis::getAbis()) {
        if (abi.second.compatible) {
            return true;
        }
    }
    return false;
}
