#include "archivalversionlist.h"

#include <QNetworkDiskCache>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonArray>
#include <QDir>
#include <QStandardPaths>

ArchivalVersionList::ArchivalVersionList() {
    m_netManager = new QNetworkAccessManager(this);
    QNetworkDiskCache* cache = new QNetworkDiskCache(m_netManager);
    cache->setCacheDirectory(QDir(QStandardPaths::writableLocation(QStandardPaths::CacheLocation)).filePath("versionCache"));
    m_netManager->setCache(cache);
}

void ArchivalVersionList::downloadLists(QStringList abis) {
    m_versions.clear();
    if (abis.size()) {
        QNetworkReply* reply = m_netManager->get(QNetworkRequest(QUrl("https://raw.githubusercontent.com/minecraft-linux/mcpelauncher-versiondb/master/versions." + abis.at(abis.size() - 1) + ".json.min")));
        connect(reply, &QNetworkReply::finished, std::bind(&ArchivalVersionList::onListDownloaded, this, reply, abis.at(abis.size() - 1), abis));
    }
}

void ArchivalVersionList::onListDownloaded(QNetworkReply* reply, QString abi, QStringList abis) {
    if (reply->error() != QNetworkReply::NoError) {
        qDebug() << "Version list failed to load, entry count:" << m_versions.size();
        emit versionsChanged();
        return;
    }
    QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
    for (QJsonValue const& el : doc.array()) {
        QJsonArray ela = el.toArray();
        ArchivalVersionInfo* info = new ArchivalVersionInfo(this);
        info->versionCode = ela.at(0).toInt();
        info->versionName = ela.at(1).toString();
        info->isBeta = ela.at(2).toInt() == 1;
        info->abi = abi;
        m_versions.push_front(info);
    }
    auto i = abis.indexOf(abi);
    if(i == 0) {          
        qDebug() << "Version list loaded, entry count:" << m_versions.size();
        emit versionsChanged();
    } else {
        QNetworkReply* reply = m_netManager->get(QNetworkRequest(QUrl("https://raw.githubusercontent.com/minecraft-linux/mcpelauncher-versiondb/master/versions." + abis.at(i - 1) + ".json.min")));
        connect(reply, &QNetworkReply::finished, std::bind(&ArchivalVersionList::onListDownloaded, this, reply, abis.at(i - 1), abis));
    }
}