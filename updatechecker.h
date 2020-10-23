#ifndef UPDATECHECKER_H
#define UPDATECHECKER_H

#include <QObject>
#include <QNetworkAccessManager>

#ifdef APPIMAGE_UPDATE_CHECK
#include <thread>
#include <appimage/update.h>
#endif

class UpdateChecker : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool active READ active NOTIFY activeChanged)
private:
    QNetworkAccessManager netAccessManager;
#ifdef APPIMAGE_UPDATE_CHECK
    std::shared_ptr<appimage::update::Updater> updater;
    std::thread updatethread;
#endif
    std::atomic_bool m_active;

    void onRequestFinished(QNetworkReply* reply);

public:
    UpdateChecker(QObject* parent = nullptr);

#ifdef APPIMAGE_UPDATE_CHECK
    ~UpdateChecker();
#endif

    bool active() const { return m_active; }

signals:
    void updateAvailable(QString downloadUrl);
    void updateCheck(bool update);
    void progress(qreal progress);
    void activeChanged();
    void requestRestart();
    void updateError(QString error);

public slots:
    void checkForUpdates();
    void startUpdate();
};

#endif // UPDATECHECKER_H
