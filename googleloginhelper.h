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
    Q_PROPERTY(GoogleAccount* account READ account NOTIFY accountInfoChanged)
    Q_PROPERTY(bool includeIncompatible READ getIncludeIncompatible WRITE setIncludeIncompatible)
    Q_PROPERTY(bool hideLatest READ hideLatest NOTIFY accountInfoChanged)

private:
    QSettings settings;
    GoogleLoginWindow* window = nullptr;
    GoogleAccount currentAccount;
    playapi::device_info device;
    playapi::file_login_cache loginCache;
    playapi::login_api login;
    bool hasAccount = false;
    bool includeIncompatible = false;

    void loadDeviceState();
    void saveDeviceState();

    void onLoginFinished(int code);

    bool getIncludeIncompatible() {
        return includeIncompatible;
    }

    void updateDevice();

    void setIncludeIncompatible(bool includeIncompatible) {
        if (this->includeIncompatible != includeIncompatible) {
            this->includeIncompatible = includeIncompatible;
            updateDevice();
        }
    }

public:
    static std::string getTokenCachePath();

    GoogleLoginHelper();

    ~GoogleLoginHelper();

    GoogleAccount* account() {
        return hasAccount ? &currentAccount : nullptr;
    }

    playapi::device_info& getDevice() { return device; }
    playapi::login_api& getLoginApi() { return login; }

    bool hideLatest();
public slots:
    void acquireAccount(QWindow *parent);

    void signOut();

    QStringList getAbis(bool includeIncompatible);

    QString GetSupportReport();

    bool isSupported();

signals:
    void accountAcquireFinished(GoogleAccount* account);

    void accountInfoChanged();

    void loginError(QString error);
};

#endif // GOOGLELOGINHELPER_H
