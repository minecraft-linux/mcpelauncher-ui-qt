#include "archivalversionlist.h"

#include <QNetworkDiskCache>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonArray>
#include <QDir>
#include <QStandardPaths>

#ifndef LAUNCHER_VERSIONDB_URL
#define LAUNCHER_VERSIONDB_URL "https://raw.githubusercontent.com/minecraft-linux/mcpelauncher-versiondb/master"
#endif

ArchivalVersionList::ArchivalVersionList() {
    m_netManager = new QNetworkAccessManager(this);
    QNetworkDiskCache* cache = new QNetworkDiskCache(m_netManager);
    cache->setCacheDirectory(QDir(QStandardPaths::writableLocation(QStandardPaths::CacheLocation)).filePath("versionCache"));
    m_netManager->setCache(cache);
}

void ArchivalVersionList::downloadLists(QStringList abis) {
    m_versionsnext.clear();
    if (abis.size()) {
        QNetworkReply* reply = m_netManager->get(QNetworkRequest(QUrl(LAUNCHER_VERSIONDB_URL "/versions." + abis.at(abis.size() - 1) + ".json.min")));
        connect(reply, &QNetworkReply::finished, std::bind(&ArchivalVersionList::onListDownloaded, this, reply, abis.at(abis.size() - 1), abis));
    } else {
        m_versions = m_versionsnext;
        emit versionsChanged();
    }
}

void ArchivalVersionList::onListDownloaded(QNetworkReply* reply, QString abi, QStringList abis) {
    QByteArray data;
    QIODevice * result;
    if (reply->error() != QNetworkReply::NoError) {
        result = m_netManager->cache()->data(QUrl(LAUNCHER_VERSIONDB_URL "/versions." + abi + ".json.min"));
        if (!result) {
            if(!result) {
                QString fileName(":/archivalversionlist/" + abi);
                QFile file(fileName);
                if(!file.open(QIODevice::ReadOnly)) {
                    m_versions = m_versionsnext;
                    qDebug() << "Version list failed to load, entry count:" << m_versions.size();
                    emit versionsChanged();
                    return;
                }
                else
                {
                    qDebug() << "Version list failed to update use embedded version";
                    data = file.readAll();
                }
                file.close();
            }
        } else {
            data = result->readAll();
            delete result;
        }
    } else {
        data = reply->readAll();
    }

    QJsonDocument doc = QJsonDocument::fromJson(data);
    for (QJsonValue const& el : doc.array()) {
        QJsonArray ela = el.toArray();
        ArchivalVersionInfo* info = new ArchivalVersionInfo(this);
        info->versionCode = ela.at(0).toInt();
        info->versionName = ela.at(1).toString();
        info->isBeta = ela.at(2).toInt() == 1;
        info->abi = abi;
        m_versionsnext.push_front(info);
    }
    auto i = abis.indexOf(abi);
    if(i == 0) {
        m_versions = m_versionsnext;
        qDebug() << "Version list loaded, entry count:" << m_versions.size();
        emit versionsChanged();
    } else {
        QNetworkReply* reply = m_netManager->get(QNetworkRequest(QUrl(LAUNCHER_VERSIONDB_URL "/versions." + abis.at(i - 1) + ".json.min")));
        connect(reply, &QNetworkReply::finished, std::bind(&ArchivalVersionList::onListDownloaded, this, reply, abis.at(i - 1), abis));
    }
}