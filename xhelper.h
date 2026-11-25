#pragma once

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
    Q_PROPERTY(QString version READ getVersion NOTIFY packageChanged)
    QString version;
public:
    void* user = nullptr;
    QString getVersion() const {
        return version;
    }
    void setVersion(const QString& ver) {
        if (version != ver) {
            version = ver;
            emit packageChanged();
        }
    }

signals:
    void packageChanged();
};

class XAsyncVariant : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariant variant READ getVariant NOTIFY done)
    QVariant variant;
public:
    QVariant getVariant() const {
        return variant;
    }
    void setVariant(const QVariant& ver) {
        if (variant != ver) {
            variant = ver;
            emit done();
        }
    }

signals:
    void done();
};

class XProgress : public QObject {
    Q_OBJECT
    Q_PROPERTY(long long progress READ getProgress NOTIFY progressChanged)
    Q_PROPERTY(long long maximum READ getMaximum NOTIFY progressChanged)
    long long progress;
    long long maximum;
public:
    long long getProgress() const {
        return progress;
    }
    long long getMaximum() const {
        return maximum;
    }
    void setProgress(long long p) {
        if (progress != p) {
            progress = p;
            emit progressChanged();
        }
    }
    void setMaximum(long long m) {
        if (maximum != m) {
            maximum = m;
            emit progressChanged();
        }
    }
signals:
    void progressChanged();
    void finished();
};

class XHelper;
class XUser : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString accountName READ getAccountName NOTIFY accountInfoChanged)
    QString accountName;
public:
    void* user = nullptr;
    XHelper* helper;
    QString getAccountName() const {
        return accountName;
    }
    void setAccountName(const QString& name) {
        if (accountName != name) {
            accountName = name;
            emit accountInfoChanged();
        }
    }
    XUser(XHelper* helper) : helper(helper) {}

    ~XUser() noexcept;
signals:
    void accountInfoChanged();
};

struct CProgress {
    size_t cur;
    size_t total;
};

struct LibXApi {
    LibXApi();
    ~LibXApi();

    void* (*initialize)();
    void (*uninitialize)(void*);
    void (*fetch_package)(void* runtime, const char* url, void *user,
        void (*success)(void *user, const void*pkg),
        void (*failure)(void *user, const char*s)
    );
    void (*destroy_package)(const void* pkg);
    void (*package_dump)(const void* pkg);
    void (*user_export)(const void* user, void*ctx, void (*callback)(void*ctx, const char* serialized));
    void* (*user_import)(const char* serialized);
    void (*user_release)(void* user);
    void (*device_release)(const void* device);
    void (*user_webview_submit)(const void* context, const char* payload);
    void (*user_refresh)(const void* runtime, const void* device, const void* user, uint64_t ucontext,
        void (*webview)(uint64_t, const void* context, const char* start_url, const char* end_url),
        void (*success)(uint64_t, const void*),
        void (*failure)(uint64_t, const char*)
    );

    const void* (*get_device_key_chain)();
    void (*download_all)(const void* runtime, const void* package, const void* device, const void* user,
        const char* url, const char* destination, uint64_t ucontext,
        void (*success)(uint64_t),
        void (*failure)(uint64_t, const char*)
    );

    CProgress (*get_progress_all)(const void* package);

    int (*run_game)(const void* runtime, const void* device, const void* user, const void* xuser, const char* source, const char* wine);

    void (*get_game_versions)(const void* runtime, const void* device, const char* content_id, const char* version, uint64_t context,
        void (*success)(uint64_t, const char*),
        void (*failure)(uint64_t, const char*)
    );

    void* handle;

    bool isValid() {
        return handle != nullptr;
    }
};

class XHelper : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool hasEncryptedCredentials READ getHasEncryptedCredentials NOTIFY accountInfoChanged)
    Q_PROPERTY(QString unlockkey READ getUnlockkey WRITE setUnlockkey NOTIFY accountInfoChanged)
    Q_PROPERTY(QVariantMap loginCache READ getLoginCache NOTIFY accountInfoChanged)
    Q_PROPERTY(QVariantMap packages READ getPackages NOTIFY packagesChanged)

private:
    void* runtime = nullptr;
    const void* device = nullptr;
    QSettings settings;
    XSignInUiQt::XLoginWindow* window = nullptr;
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
    LibXApi api;

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

    void signOut(const QString& accountName);

    XProgress* downloadPackage(const QString& packageId, const QString& version);
    void runPackage(const QString& packageId, const QString& version, const QString& user);
    XAsyncVariant* resolvePackage(const QString& packageId, const QString& version);
signals:
    void accountAcquireFinished(QObject* account);

    void accountInfoChanged();
    void packagesChanged();

    void loginError(QString error);
};
