#include "archivalversionlist.h"

#include <QNetworkDiskCache>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonArray>
#include <QDir>
#include <QStandardPaths>

#define GET_LIST_URL "https://raw.githubusercontent.com/minecraft-linux/mcpelauncher-versiondb/master/versions.json.min"

ArchivalVersionList::ArchivalVersionList() {
    m_netManager = new QNetworkAccessManager(this);
    QNetworkDiskCache* cache = new QNetworkDiskCache(m_netManager);
    cache->setCacheDirectory(QDir(QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation)).filePath("versionCache"));
    m_netManager->setCache(cache);
    downloadList();
}

void ArchivalVersionList::downloadList() {
    QNetworkReply* reply = m_netManager->get(QNetworkRequest(QUrl(GET_LIST_URL)));
    connect(reply, &QNetworkReply::finished, this, &ArchivalVersionList::onListDownloaded);
}

void ArchivalVersionList::onListDownloaded() {
    QNetworkReply* reply = (QNetworkReply*) sender();
    if (reply->error() != QNetworkReply::NoError)
        return;
    QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
    m_versions.clear();
    for (QJsonValue const& el : doc.array()) {
        QJsonArray ela = el.toArray();
        ArchivalVersionInfo* info = new ArchivalVersionInfo(this);
        info->versionCode = ela.at(0).toInt();
        info->versionName = ela.at(1).toString();
        info->isBeta = ela.at(2).toInt() == 1;
        m_versions.push_front(info);
    }
    qDebug() << "Version list loaded, entry count:" << m_versions.size();
    emit versionsChanged();
}
