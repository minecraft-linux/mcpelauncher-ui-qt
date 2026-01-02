#pragma once
#include <QObject>
#include <QString>
#include <QMap>
#include "modmanager.h"
#include "profilemanager.h"
#include "archivalversionlist.h"

class UpdateManager : public QObject {
    Q_OBJECT

    ModManager m_modManager;
    ProfileManager* m_profileManager;
    ArchivalVersionList* m_versionList;
    int m_maxCompatVersion;
public:
    Q_PROPERTY(ProfileManager* profileManager MEMBER m_profileManager)
    Q_PROPERTY(ArchivalVersionList* versionList MEMBER m_versionList)
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