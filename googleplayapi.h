#ifndef GOOGLEPLAYAPI_H
#define GOOGLEPLAYAPI_H

#include <QObject>
#include <QMutex>
#include <QThread>
#include <QSettings>
#include <future>
#include <playapi/api.h>

class GoogleLoginHelper;

class GooglePlayApi : public QObject {
    Q_OBJECT
    Q_PROPERTY(GoogleLoginHelper* login WRITE setLogin)

private:
    QScopedPointer<playapi::api> api;
    GoogleLoginHelper* loginHelper;
    QMutex checkinMutex;
    playapi::checkin_result checkinResult;
    std::promise<std::pair<bool, bool>> tosApprovalPromise;

    void loadCheckinInfo();
    void saveCheckinInfo();

    void loadApiInfo();
    void saveApiInfo();

public:
    explicit GooglePlayApi(QObject *parent = nullptr);

    void setLogin(GoogleLoginHelper* helper);

    GoogleLoginHelper* getLogin() { return loginHelper; }

    playapi::api* getApi() { return api.get(); }

signals:
    void ready();

    void initError(QString const& text);

    void tosApprovalRequired(QString const& tosText, QString const& marketingText);

    void appInfoReceived(QString const& packageName, QString const& version, int versionCode);

public slots:
    void handleCheckinAndTos();

    void updateLogin();

    void requestAppInfo(QString const& packageName);

    void setTosApproved(bool approved, bool marketing) {
        tosApprovalPromise.set_value({approved, marketing});
    }

};

#endif // GOOGLEPLAYAPI_H
