#include "archivalversionlist.h"

#include <QNetworkDiskCache>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonArray>
#include <QDir>
#include <QStandardPaths>

#if (defined(__arm__) || defined(__aarch64__)) && (!defined(FORCE_ARM) || FORCE_ARM == 1 )
#define branch32 "armeabi-v7a"
#define branch "arm64-v8a"
#else
#define branch32 "x86"
#define branch "x86_64"
#endif

#define GET_LIST_URL(b) "https://raw.githubusercontent.com/minecraft-linux/mcpelauncher-versiondb/master/versions." b ".json.min"

ArchivalVersionList::ArchivalVersionList() {
    m_netManager = new QNetworkAccessManager(this);
    QNetworkDiskCache* cache = new QNetworkDiskCache(m_netManager);
    cache->setCacheDirectory(QDir(QStandardPaths::writableLocation(QStandardPaths::CacheLocation)).filePath("versionCache"));
    m_netManager->setCache(cache);
    downloadList();
}

void ArchivalVersionList::downloadList() {
    QNetworkReply* reply = m_netManager->get(QNetworkRequest(QUrl(GET_LIST_URL(branch32))));
    connect(reply, &QNetworkReply::finished, this, &ArchivalVersionList::onListDownloaded32);
}

void ArchivalVersionList::onListDownloaded32() {
    QNetworkReply* reply = (QNetworkReply*) sender();
    if (reply->error() != QNetworkReply::NoError)
        return;
    QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
    m_versions.clear();
    for (QJsonValue const& el : doc.array()) {
        QJsonArray ela = el.toArray();
        ArchivalVersionInfo* info = new ArchivalVersionInfo(this);
        info->versionCode = ela.at(0).toInt();
        info->versionName = ela.at(1).toString() + " (32bit)";
        info->isBeta = ela.at(2).toInt() == 1;
        m_versions.push_front(info);
    }
    qDebug() << "Version list loaded, entry count:" << m_versions.size();
    emit versionsChanged();
#if defined(__x86_64__) || defined(__aarch64__)
    QNetworkReply* reply2 = m_netManager->get(QNetworkRequest(QUrl(GET_LIST_URL(branch))));
    connect(reply2, &QNetworkReply::finished, this, &ArchivalVersionList::onListDownloaded);
#endif
}


void ArchivalVersionList::onListDownloaded() {
    QNetworkReply* reply = (QNetworkReply*) sender();
    if (reply->error() != QNetworkReply::NoError)
        return;
    QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
    for (QJsonValue const& el : doc.array()) {
        QJsonArray ela = el.toArray();
        ArchivalVersionInfo* info = new ArchivalVersionInfo(this);
        info->versionCode = ela.at(0).toInt();
        info->versionName = ela.at(1).toString() + " (64bit)";
        info->isBeta = ela.at(2).toInt() == 1;
        m_versions.push_front(info);
    }
    qDebug() << "Version list loaded, entry count:" << m_versions.size();
    emit versionsChanged();
}
