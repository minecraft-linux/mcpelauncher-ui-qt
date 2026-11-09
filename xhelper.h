#ifndef XHelper_H
#define XHelper_H

#include <QObject>
#include <QSettings>
#include "encrypted_file_login_cache.h"
#include "googleaccount.h"

class QWindow;
namespace XSignInUiQt {
class XLoginWindow;
}

class XUser : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString accountName READ getAccountName NOTIFY accountInfoChanged)
    QString accountName;
public:
    void* user = nullptr;
    QString getAccountName() const {
        return accountName;
    }
    void setAccountName(const QString& name) {
        if (accountName != name) {
            accountName = name;
            emit accountInfoChanged();
        }
    }
signals:
    void accountInfoChanged();
};

class XHelper : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool hasEncryptedCredentials READ getHasEncryptedCredentials NOTIFY accountInfoChanged)
    Q_PROPERTY(QString unlockkey READ getUnlockkey WRITE setUnlockkey NOTIFY accountInfoChanged)

private:
    void* runtime = nullptr;
    QSettings settings;
    XSignInUiQt::XLoginWindow* window = nullptr;
    GoogleAccount currentAccount;
    bool hasAccount = false;
    bool hasEncryptedCredentials = false;
    QString unlockkey;
    QMap<QString, XUser*> loginCache;

    static std::string getTokenCachePath();

    void loadDeviceState();
    void saveDeviceState();

    void onLoginFinished(int code);

    QString getUnlockkey() {
        return unlockkey;
    }

    void loadAccount();

    void updateDevice();

    void setUnlockkey(QString key) {
        if (this->unlockkey != key) {
            this->unlockkey = key;
            loadAccount();
        }
    }

public:
    bool getHasEncryptedCredentials() {
        return hasEncryptedCredentials;
    }
    XHelper();

    ~XHelper();

    bool hideLatest();
public slots:
    void acquireAccount(QWindow *parent);

    void signOut();
signals:
    void accountAcquireFinished(QObject* account);

    void accountInfoChanged();

    void loginError(QString error);
};

#endif // XHelper_H
