#ifndef ARCHIVEVERSIONLIST_H
#define ARCHIVEVERSIONLIST_H

#include <QNetworkAccessManager>

class ArchivalVersionInfo : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString versionName MEMBER versionName CONSTANT)
    Q_PROPERTY(int versionCode MEMBER versionCode CONSTANT)
    Q_PROPERTY(bool isBeta MEMBER isBeta CONSTANT)

public:
    QString versionName;
    int versionCode;
    bool isBeta;

    ArchivalVersionInfo(QObject* parent = nullptr) : QObject(parent) {}

};

class ArchivalVersionList : public QObject {
    Q_OBJECT
    Q_PROPERTY(QList<QObject*> versions READ versions NOTIFY versionsChanged)

private:
    QNetworkAccessManager* m_netManager;
    QList<QObject*> m_versions;

    void downloadList();

public:
    ArchivalVersionList();

    QList<QObject*> const& versions() const { return m_versions; }

private slots:
    void onListDownloaded();

signals:
    void versionsChanged();

};

#endif // ARCHIVEVERSIONLIST_H
