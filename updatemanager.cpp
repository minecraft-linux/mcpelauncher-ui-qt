#include "updatemanager.h"

#include "downloadtask.h"
#include "zipextractiontask.h"
#include <QtCore/qstandardpaths.h>
#include <QVersionNumber>

UpdateManager::UpdateManager(QObject *parent)
    : QObject(parent)
{
    connect(&m_modManager, &ModManager::modListUpdated, this, [this]() {
        // QMap<QString, ModInfo> currentVersions;
        // for (const ModInfo& mod : m_modManager.listMods()) {
        //     // if (mod.name == "mcpelauncher-update") {
        //     //     // Current version is up-to-date
        //     //     return;
        //     // }
        //     auto&& previousVersion = currentVersions[mod.name];
        //     if (previousVersion.version.isEmpty() || previousVersion.version < mod.version) {
        //         currentVersions[mod.name] = mod;
        //     }
        //     QVersionNumber::fromString(mod.version);
        // }

        // for(auto&& path : m_profileManager.activeProfile()->mods) {
        //     //m_modManager.loadMod(path);
        // }
        if(m_versionList->versions().isEmpty()) {
            emit noUpdateAvailable();
            return;
        }
        auto&& maxKnownVersion = m_versionList->versions().first()->property("versionCode").toInt();
        auto&& maxKnownVersionAbi = m_versionList->versions().first()->property("abi").toString();

        // for(auto&& path : m_profileManager.activeProfile()->mods) {
        //     //m_modManager.loadMod(path);
        // }

        // For simplicity, we assume the first mod named "mcpelauncher-update" is the update mod.
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

            // if (mod.name == "mcpelauncher-updates") {
            //     auto vList = mod.metadata.value("versions").toList();
                
            //     for(auto it = vList.rbegin(); it != vList.rend(); ++it) {
            //         QString version = it->toMap().value("version").toString();
            //         if (availableVersion > currentVersion) {
            //             QString downloadUrl = it->toMap().value("assets").toMap().value("arm64-v8a").toString();
            //             emit updateAvailable(mod.name, version, {{"arm64-v8a", downloadUrl}}, it->toMap());
            //             return;
            //         }
            //     }

            //     QString latestVersion = vList.rbegin()->toMap().value("version").toString();
            //     QString downloadUrl = vList.rbegin()->toMap().value("assets").toMap().value("arm64-v8a").toString();
            //     emit updateAvailable(latestVersion, downloadUrl);
            //     return;
            // }
        }
        emit noUpdateAvailable();
    });
}

Q_INVOKABLE void UpdateManager::checkForUpdates()
{
    m_modManager.downloadModList();
}

Q_INVOKABLE void UpdateManager::downloadUpdate(const QString& mod, const QString& version, const QString& arch, const QString& url, const QVariantMap& metadata)
{
    DownloadTask* task = new DownloadTask(this);
    QList<DownloadDataWrapper*> downloadList;
    auto entry = new DownloadDataWrapper(this);
    entry->setUrl(url);
    entry->setComponentName(mod + "-" + version);
    downloadList.append(entry);
    auto connections = new QList<QMetaObject::Connection>();
    connections->append(connect(task, &DownloadTask::progress, this, [this](qreal u) {
        emit progress(u);
    }));
    connections->append(connect(task, &DownloadTask::error, this, [this, connections](const QString &err) {
        emit updateFailed(err);
        delete connections;
    }));
    connections->append(connect(task, &DownloadTask::finished, this, [this, task, connections, mod, version, arch, metadata]() {
        connections->clear();
        auto files = task->filePaths();
        task->deleteLater();
        ZipExtractionTask* extractTask = new ZipExtractionTask(this);
        extractTask->setSources(files);
        auto baseDir = m_modManager.getRoot() + "/" + mod + "/" + version + "/" + arch;
        QDir(baseDir).mkpath(".");
        extractTask->setTargetDir(baseDir);
        connections->append(connect(extractTask, &ZipExtractionTask::progress, this, [this](qreal p) {
            emit progress(p);
        }));
        connections->append(connect(extractTask, &ZipExtractionTask::error, this, [this, extractTask, connections](const QString &err) {
            QDir targetDir(extractTask->targetDir());
            targetDir.removeRecursively();
            emit updateFailed(err);
            delete connections;
            extractTask->deleteLater();
        }));
        connections->append(connect(extractTask, &ZipExtractionTask::finished, this, [this, extractTask, connections, mod, version, arch, metadata]() {
            emit progress(1.0);
            m_modManager.saveMod(mod, version, arch, metadata);
            emit finished();
            delete connections;
            extractTask->deleteLater();
        }));
        extractTask->start();
    }));
    task->startDownload(downloadList);
}
