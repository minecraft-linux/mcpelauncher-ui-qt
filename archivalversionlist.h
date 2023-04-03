#ifndef ARCHIVEVERSIONLIST_H
#define ARCHIVEVERSIONLIST_H

#include <QNetworkAccessManager>

class ArchivalVersionInfo : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString versionName MEMBER versionName CONSTANT)
    Q_PROPERTY(int versionCode MEMBER versionCode CONSTANT)
    Q_PROPERTY(bool isBeta MEMBER isBeta CONSTANT)
    Q_PROPERTY(QString abi MEMBER abi CONSTANT)

public:
    QString versionName;
    int versionCode;
    bool isBeta;
    QString abi;

    ArchivalVersionInfo(QObject* parent = nullptr) : QObject(parent) {}

};

class RollforwardVersionRange : public QObject {
    Q_OBJECT
    Q_PROPERTY(int minVersionCode MEMBER minVersionCode CONSTANT)
    Q_PROPERTY(int maxVersionCode MEMBER maxVersionCode CONSTANT)

public:
    int minVersionCode;
    int maxVersionCode;

    RollforwardVersionRange(QObject* parent = nullptr) : QObject(parent) {}

};

class ArchivalVersionList : public QObject {
    Q_OBJECT
    Q_PROPERTY(QList<QObject*> versions READ versions NOTIFY versionsChanged)
    Q_PROPERTY(QList<QObject*> rollforwardVersionRange READ rollforwardVersionRange NOTIFY versionsChanged)

private:
    QNetworkAccessManager* m_netManager;
    QList<QObject*> m_versions;
    QList<QObject*> m_versionsnext;
    QList<QObject*> m_rollforwardVersionRange;
    QString m_baseUrl;
    QString m_defBaseUrl;

    void onListDownloaded(QNetworkReply* reply, QString abi, QStringList abis);

public:
    ArchivalVersionList(QString baseUrl);

    QList<QObject*> const& versions() const { return m_versions; }
    QList<QObject*> const& rollforwardVersionRange() const { return m_rollforwardVersionRange; }

    void downloadLists(QStringList abis, QString versionDBUrl);

signals:
    void versionsChanged();

};

#endif // ARCHIVEVERSIONLIST_H
