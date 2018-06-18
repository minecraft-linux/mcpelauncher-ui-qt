#include "googleloginhelper.h"

#include <googleloginwindow.h>
#include <QStandardPaths>
#include <QDir>
#include <QWindow>

std::string GoogleLoginHelper::getTokenCachePath() {
    return QDir(QStandardPaths::writableLocation(QStandardPaths::CacheLocation)).filePath("playapi_token_cache.conf").toStdString();
}

GoogleLoginHelper::GoogleLoginHelper() : loginCache(getTokenCachePath()), login(device, loginCache) {
    settings.beginGroup("googlelogin");
    if (settings.contains("identifier")) {
        currentAccount.setAccountIdentifier(settings.value("identifier").toString());
        currentAccount.setAccountUserId(settings.value("userId").toString());
        currentAccount.setAccountToken(settings.value("token").toString());
        login.set_token(currentAccount.accountIdentifier().toStdString(), currentAccount.accountToken().toStdString());
        hasAccount = true;
    }
    settings.endGroup();
}

GoogleLoginHelper::~GoogleLoginHelper() {
    delete window;
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
        login.perform_with_access_token(window->accountToken().toStdString(), window->accountIdentifier().toStdString(), true)->call();
        currentAccount.setAccountIdentifier(window->accountIdentifier());
        currentAccount.setAccountUserId(window->accountUserId());
        currentAccount.setAccountToken(QString::fromStdString(login.get_token()));
        settings.beginGroup("googlelogin");
        settings.setValue("identifier", currentAccount.accountIdentifier());
        settings.setValue("userId", currentAccount.accountUserId());
        settings.setValue("token", currentAccount.accountToken());
        settings.endGroup();
        hasAccount = true;
        accountAcquireFinished(&currentAccount);
    } else {
        accountAcquireFinished(nullptr);
    }
    window = nullptr;
}
