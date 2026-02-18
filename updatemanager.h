#pragma once
#include <mutex>
#include <atomic>
#include <QObject>
#include <QString>
#include <QMap>
#include "modmanager.h"
#include "profilemanager.h"
#include "archivalversionlist.h"

class UpdateManager : public QObject {
    Q_OBJECT

    ModManager m_modManager;
    QVariantList m_versionList;
    std::atomic_bool checkedForUpdates = false;
    std::mutex sync;
    
    int m_maxCompatVersion;
private:
    void checkForUpdatesInModDb();
public:
    Q_PROPERTY(QVariantList versionList MEMBER m_versionList)
    Q_PROPERTY(int maxCompatVersion MEMBER m_maxCompatVersion)
    explicit UpdateManager(QObject* parent = nullptr);
    Q_INVOKABLE void checkForUpdates();
    Q_INVOKABLE void downloadUpdate(const QString& mod, const QString& version, const QString& arch, const QString& url, const QVariantMap& metadata);
signals:
    void updateAvailable(const QString& mod, const QString& version, const QString& arch, const QString& url, const QVariantMap& metadata);
    void noUpdateAvailable();
    void updateFailed(const QString& error);
    void progress(qreal percentage);
    void finished();
};