#ifndef GOOGLELOGINHELPER_H
#define GOOGLELOGINHELPER_H

#include <QObject>
#include <QSettings>
#include <playapi/login.h>
#include <playapi/device_info.h>
#include <playapi/file_login_cache.h>
#include "googleaccount.h"

class QWindow;
class GoogleLoginWindow;

class GoogleLoginHelper : public QObject {
    Q_OBJECT
    Q_PROPERTY(GoogleAccount* account READ account)

private:
    QSettings settings;
    GoogleLoginWindow* window = nullptr;
    GoogleAccount currentAccount;
    playapi::device_info device;
    playapi::file_login_cache loginCache;
    playapi::login_api login;
    bool hasAccount = false;

    static std::string getTokenCachePath();

    void loadDeviceState();
    void saveDeviceState();

    void onLoginFinished(int code);

public:
    GoogleLoginHelper();

    ~GoogleLoginHelper();

    GoogleAccount* account() {
        return hasAccount ? &currentAccount : nullptr;
    }

    playapi::device_info& getDevice() { return device; }
    playapi::login_api& getLoginApi() { return login; }

public slots:
    void acquireAccount(QWindow *parent);

signals:
    void accountAcquireFinished(GoogleAccount* account);

};

#endif // GOOGLELOGINHELPER_H
