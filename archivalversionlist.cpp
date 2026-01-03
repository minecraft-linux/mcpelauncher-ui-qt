#include "archivalversionlist.h"

#include <QNetworkDiskCache>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonArray>
#include <QDir>
#include <QStandardPaths>

ArchivalVersionList::ArchivalVersionList(QString baseUrl) {
    m_defBaseUrl = baseUrl;
    m_netManager = new QNetworkAccessManager(this);
    QNetworkDiskCache* cache = new QNetworkDiskCache(m_netManager);
    cache->setCacheDirectory(QDir(QStandardPaths::writableLocation(QStandardPaths::CacheLocation)).filePath("versionCache"));
    m_netManager->setCache(cache);
}

void ArchivalVersionList::updateExtraVersions(QList<QObject*>& versions) {
    for(auto&& extraVer : m_extraVersions) {
        ArchivalVersionInfo* info = qobject_cast<ArchivalVersionInfo*>(extraVer);
        if(!info) continue;
        bool found = false;
        for(int i = 0; i < versions.size(); i++) {
            ArchivalVersionInfo* ver = qobject_cast<ArchivalVersionInfo*>(versions.at(i));
            if(!ver) continue;
            if(ver->versionCode == info->versionCode && ver->abi == info->abi) {
                found = true;
                break;
            }
        }
        if(!found) {
            versions.push_front(extraVer);
        }
    }
}

void ArchivalVersionList::setExtraVersions(QVariantList extraVersions) {
    if(m_extraVersions.size() > 0) {
        for (int i = m_versions.size() - 1; i >= 0; --i) {
            if (m_extraVersions.contains(m_versions[i])) {
                m_versions.removeAt(i);
            }
        }
        m_extraVersions.clear();
    }
    for(auto&& ver : extraVersions) {
        auto entry = new ArchivalVersionInfo(this);
        entry->versionCode = ver.toMap().value("versionCode").toInt();
        entry->versionName = ver.toMap().value("versionName").toString();
        entry->isBeta = ver.toMap().value("isBeta").toBool();
        entry->abi = ver.toMap().value("abi").toString();
        m_extraVersions.append(entry);
    }

    updateExtraVersions(m_versions);

    emit versionsChanged();
}

void ArchivalVersionList::downloadLists(QStringList abis, QString baseUrl) {
    m_versionsnext.clear();
    m_rollforwardVersionRange.clear();
    m_baseUrl = baseUrl.isEmpty() ? m_defBaseUrl : baseUrl;
    if (abis.size()) {
        auto && versiondburl = m_baseUrl + "/versions." + abis.at(abis.size() - 1) + ".json.min";
        qDebug() << "Downloading Versionsdb" << versiondburl;
        QNetworkRequest request{QUrl(versiondburl)};
        request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
        QNetworkReply* reply = m_netManager->get(request);
        connect(reply, &QNetworkReply::finished, std::bind(&ArchivalVersionList::onListDownloaded, this, reply, abis.at(abis.size() - 1), abis));
    } else {
        updateExtraVersions(m_versionsnext);
        m_versions = m_versionsnext;
        emit versionsChanged();
    }
}

void ArchivalVersionList::onListDownloaded(QNetworkReply* reply, QString abi, QStringList abis) {
    QByteArray data;
    QIODevice * result;
    if (reply->error() != QNetworkReply::NoError) {
        result = m_netManager->cache()->data(QUrl(m_baseUrl + "/versions." + abi + ".json.min"));
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
        // Roll forward
        if(ela.count() > 3 && ela.at(0).toInt() < ela.at(3).toInt()) {
            RollforwardVersionRange* rollfwd = new RollforwardVersionRange(this);
            rollfwd->minVersionCode = ela.at(0).toInt();
            rollfwd->maxVersionCode = ela.at(3).toInt();
            m_rollforwardVersionRange.push_back(rollfwd);
        }
        info->abi = abi;
        m_versionsnext.push_front(info);
    }
    auto i = abis.indexOf(abi);
    if(i == 0) {
        updateExtraVersions(m_versionsnext);
        m_versions = m_versionsnext;
        qDebug() << "Version list loaded, entry count:" << m_versions.size();
        emit versionsChanged();
    } else {
        auto && versiondburl = m_baseUrl + "/versions." + abis.at(i - 1) + ".json.min";
        qDebug() << "Downloading Versionsdb" << versiondburl;
        QNetworkRequest request{QUrl(versiondburl)};
        request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
        QNetworkReply* reply = m_netManager->get(request);
        connect(reply, &QNetworkReply::finished, std::bind(&ArchivalVersionList::onListDownloaded, this, reply, abis.at(i - 1), abis));
    }
}
