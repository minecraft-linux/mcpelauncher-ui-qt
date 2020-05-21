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

class ArchivalVersionList : public QObject {
    Q_OBJECT
    Q_PROPERTY(QList<QObject*> versions READ versions NOTIFY versionsChanged)

private:
    QNetworkAccessManager* m_netManager;
    QList<QObject*> m_versions;

    void onListDownloaded(QNetworkReply* reply, QString abi);

public:
    ArchivalVersionList();

    QList<QObject*> const& versions() const { return m_versions; }

    void downloadLists(std::vector<QString> abis);

signals:
    void versionsChanged();

};

#endif // ARCHIVEVERSIONLIST_H
