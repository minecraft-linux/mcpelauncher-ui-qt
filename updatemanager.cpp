#include "updatemanager.h"

#include "downloadtask.h"
#include "zipextractiontask.h"
#include <QtCore/qstandardpaths.h>
#include <QVersionNumber>
#include <QtConcurrent>
#include <QDebug>

static QVariant versionsInfoProperty(const QVariant& v, const char* n) {
    if(v.canConvert<QObject*>()) {
        QObject *obj = qvariant_cast<QObject*>(v);
        return obj ? obj->property(n) : QVariant();
    }
    return v.toMap()[n];
}

UpdateManager::UpdateManager(QObject *parent)
    : QObject(parent)
{
    connect(&m_modManager, &ModManager::modListUpdated, this, &UpdateManager::checkForUpdatesInModDb);
}

void UpdateManager::checkForUpdatesInModDb() {
    std::unique_lock<std::mutex> l{sync, std::try_to_lock};
    if(!l.owns_lock()) {
        qDebug() << "Cancel concurrent checkForUpdatesInModDb";
        return;
    }
    if(m_versionList.empty()) {
        emit noUpdateAvailable();
        return;
    }
    auto&& maxKnownVersion = versionsInfoProperty(m_versionList.first(), "versionCode").toInt();
    auto&& maxKnownVersionAbi = versionsInfoProperty(m_versionList.first(), "abi").toString();

    for (const ModInfo& mod : m_modManager.remoteMods()) {
        auto vList = mod.metadata.value("versions").toList();
        for(auto it = vList.rbegin(); it != vList.rend(); ++it) {
            if(it->toMap().value("compatVersion").toInt() > maxKnownVersion) {
                continue;
            }
            auto extraVersions = it->toMap().value("extraVersions").toList();
            bool isApplicable = false;
            for(auto et = extraVersions.rbegin(); et != extraVersions.rend(); ++et) {
                auto codes = et->toMap().value("codes").toMap();
                if(codes.contains(maxKnownVersionAbi) && codes[maxKnownVersionAbi].toInt() > maxKnownVersion) {
                    isApplicable = true;
                    break;
                }   
            }
            if(!isApplicable) {
                continue;
            }
            QString version = it->toMap().value("version").toString();
            auto result = m_modManager.loadMod(mod.name, version, maxKnownVersionAbi);
            if (result.value("metadata").isNull()) {
                QString downloadUrl = it->toMap().value("assets").toMap().value(maxKnownVersionAbi).toString();
                QVariantMap metadata;
                metadata["metadata"] = mod.metadata;
                metadata["version"] = it->toMap();
                metadata["arch"] = maxKnownVersionAbi;
                emit updateAvailable(mod.name, version, maxKnownVersionAbi, downloadUrl, metadata);
                return;
            } else {
                emit updateAvailable(mod.name, version, maxKnownVersionAbi, QString(), result);
            }
        }
    }
    emit noUpdateAvailable();
}

Q_INVOKABLE void UpdateManager::checkForUpdates()
{
    qDebug() << "UpdateManager::checkForUpdates()";
    if(getenv("SAFE_MODE")) {
        qDebug() << "UpdateManager::checkForUpdates() dropping due to SAFE_MODE";
        return;
    }
    bool e = false;
    if(checkedForUpdates.compare_exchange_weak(e, true)) {
        qDebug() << "UpdateManager::checkForUpdates() downloadModList for checking";
        m_modManager.downloadModList();
    } else if(!m_modManager.remoteMods().empty()) {
        qDebug() << "UpdateManager::checkForUpdates() checkForUpdatesInModDb";
        checkForUpdatesInModDb();
    } else {
        qDebug() << "UpdateManager::checkForUpdates() request dropped";
    }
}

Q_INVOKABLE void UpdateManager::downloadUpdate(const QString& mod, const QString& version, const QString& arch, const QString& url, const QVariantMap& metadata)
{
    ZipExtractionTask* extractTask = new ZipExtractionTask();
    extractTask->moveToThread(extractTask);
    DownloadTask* task = new DownloadTask();
    QList<DownloadDataWrapper*> downloadList;
    auto entry = new DownloadDataWrapper(task);
    entry->setUrl(url);
    entry->setComponentName(mod + "-" + version);
    downloadList.append(entry);
    auto connections = new QList<QMetaObject::Connection>();
    connections->append(connect(task, &DownloadTask::progress, this, [this](qreal u) {
        emit progress(u);
    }));
    connections->append(connect(task, &DownloadTask::error, this, [this, extractTask, connections](const QString &err) {
        emit updateFailed(err);
        delete connections;
        extractTask->deleteLater();
    }));
    connections->append(connect(task, &DownloadTask::finished, this, [this, extractTask, task, connections, mod, version, arch, metadata]() {
        connections->clear();
        auto files = task->filePaths();
        // Make QThread::finished delete the thread once done
        extractTask->setSources(files);
        auto baseDir = m_modManager.getRoot() + "/" + mod + "/" + version + "/" + arch;
        QDir(baseDir).mkpath(".");
        extractTask->setTargetDir(baseDir);
        connections->append(connect(extractTask, &ZipExtractionTask::progress, this, [this](qreal p) {
            emit progress(p);
        }));
        connections->append(connect(extractTask, &ZipExtractionTask::error, this, [this, extractTask](const QString &err) {
            QDir targetDir(extractTask->targetDir());
            targetDir.removeRecursively();
            emit updateFailed(err);
        }));
        connections->append(connect(extractTask, &ZipExtractionTask::finished, this, [this, mod, version, arch, metadata, extractTask]() {
            emit progress(1.0);
            if(!m_modManager.saveMod(mod, version, arch, metadata)) {
                QDir targetDir(extractTask->targetDir());
                targetDir.removeRecursively();
                emit updateFailed(QObject::tr("Failed to save mod %1 version %2 for arch %3").arg(mod, version, arch));
            } else {
                emit finished();
            }
        }));
        connections->append(QObject::connect(extractTask, &QThread::finished, extractTask, [connections, extractTask]() {
            QThreadPool::globalInstance()->start([connections, extractTask]() {
                extractTask->wait();
                delete extractTask;
                delete connections;
            });
        }));
        extractTask->start();
    }));
    task->startDownload(downloadList);
}
