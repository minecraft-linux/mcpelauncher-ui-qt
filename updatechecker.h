#ifndef UPDATECHECKER_H
#define UPDATECHECKER_H

#include <QObject>
#include <QNetworkAccessManager>

class UpdateChecker : public QObject {
    Q_OBJECT
private:
    QNetworkAccessManager netAccessManager;

    void onRequestFinished(QNetworkReply* reply);

public:
    UpdateChecker(QObject* parent = nullptr);

signals:
    void updateAvailable(QString downloadUrl);

public slots:
    void sendRequest();
};

#endif // UPDATECHECKER_H
