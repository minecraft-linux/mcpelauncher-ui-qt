#ifndef GOOGLEVERSIONCHANNEL_H
#define GOOGLEVERSIONCHANNEL_H

#include <QObject>
#include <QSettings>

class GooglePlayApi;

class GoogleVersionChannel : public QObject {
    Q_OBJECT
    Q_PROPERTY(GooglePlayApi* playApi WRITE setPlayApi)
    Q_PROPERTY(QString latestVersion READ latestVersion NOTIFY latestVersionChanged)
    Q_PROPERTY(QString latestVersionCode READ latestVersionCode NOTIFY latestVersionChanged)
private:
    QSettings m_settings;
    GooglePlayApi* m_playApi = nullptr;
    QString m_latestVersion;
    qint32 m_latestVersionCode;

    void onApiReady();

    void onAppInfoReceived(QString const& packageName, QString const& version, int versionCode);

public:
    GoogleVersionChannel();

    void setPlayApi(GooglePlayApi* value);

    QString const& latestVersion() const { return m_latestVersion; }
    qint32 latestVersionCode() const { return m_latestVersionCode; }

public slots:

signals:
    void latestVersionChanged();

};

#endif // GOOGLEVERSIONCHANNEL_H
