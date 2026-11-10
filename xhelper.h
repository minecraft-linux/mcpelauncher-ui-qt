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

class XPackage : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString version READ getVersion NOTIFY accountInfoChanged)
    QString version;
public:
    void* user = nullptr;
    QString getVersion() const {
        return version;
    }
    void setVersion(const QString& ver) {
        if (version != ver) {
            version = ver;
            emit accountInfoChanged();
        }
    }

signals:
    void accountInfoChanged();
};


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
    Q_PROPERTY(QVariantMap loginCache READ getLoginCache NOTIFY accountInfoChanged)
    Q_PROPERTY(QVariantMap packages READ getPackages NOTIFY packagesChanged)

private:
    void* runtime = nullptr;
    QSettings settings;
    XSignInUiQt::XLoginWindow* window = nullptr;
    GoogleAccount currentAccount;
    bool hasAccount = false;
    bool hasEncryptedCredentials = false;
    QString unlockkey;
    QMap<QString, XUser*> loginCache;
    QMap<QString, XPackage*> packages;

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
    QVariantMap getLoginCache() {
        QVariantMap map;
        for (auto it = loginCache.begin(); it != loginCache.end(); ++it) {
            map[it.key()] = QVariant::fromValue(it.value());
        }
        return map;
    }
    QVariantMap getPackages() {
        QVariantMap map;
        for (auto it = packages.begin(); it != packages.end(); ++it) {
            map[it.key()] = QVariant::fromValue(it.value());
        }
        return map;
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
    void packagesChanged();

    void loginError(QString error);
};

#endif // XHelper_H
