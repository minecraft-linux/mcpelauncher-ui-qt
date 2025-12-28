#pragma once
#include <QObject>
#include <QString>
#include "modmanager.h"
#include "profilemanager.h"

class UpdateManager : public QObject {
    Q_OBJECT

    ModManager m_modManager;
    ProfileManager m_profileManager;
public:
    explicit UpdateManager(QObject* parent = nullptr);
    Q_INVOKABLE void checkForUpdates();
    Q_INVOKABLE void downloadUpdate(const QString& version, const QString& url);
signals:
    void updateAvailable(const QString& version, const QString& url);
    void noUpdateAvailable();
    void updateFailed(const QString& error);
    void progress(qreal percentage);
};