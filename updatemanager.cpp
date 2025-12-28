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

        for(auto&& path : m_profileManager.activeProfile()->mods) {
            //m_modManager.loadMod(path);
        }

        // For simplicity, we assume the first mod named "mcpelauncher-update" is the update mod.
        for (const ModInfo& mod : m_modManager.remoteMods()) {
            if (mod.name == "mcpelauncher-updates") {
                auto vList = mod.metadata.value("versions").toList();

                QString latestVersion = vList.rbegin()->toMap().value("version").toString();
                QString downloadUrl = vList.rbegin()->toMap().value("assets").toMap().value("arm64-v8a").toString();
                emit updateAvailable(latestVersion, downloadUrl);
                return;
            }
        }
        emit noUpdateAvailable();
    });
}

Q_INVOKABLE void UpdateManager::checkForUpdates()
{
    m_modManager.downloadModList();
}

Q_INVOKABLE void UpdateManager::downloadUpdate(const QString &version, const QString &url)
{
    DownloadTask* task = new DownloadTask(this);
    QList<DownloadDataWrapper*> downloadList;
    auto entry = new DownloadDataWrapper(this);
    entry->setUrl(url);
    entry->setComponentName("mcpelauncher-updates-" + version);
    downloadList.append(entry);
    auto connections = new QList<QMetaObject::Connection>();
    connections->append(connect(task, &DownloadTask::progress, this, [this](qreal u) {
        emit progress(u);
    }));
    connections->append(connect(task, &DownloadTask::error, this, [this, connections](const QString &err) {
        emit updateFailed(err);
        delete connections;
    }));
    connections->append(connect(task, &DownloadTask::finished, this, [this, task, connections, version]() {
        connections->clear();
        auto files = task->filePaths();
        task->deleteLater();
        ZipExtractionTask* extractTask = new ZipExtractionTask(this);
        extractTask->setSources(files);
        extractTask->setTargetDir(m_modManager.getRoot() + "/mcpelauncher-updates/" + version);
        connections->append(connect(extractTask, &ZipExtractionTask::progress, this, [this](qreal p) {
            emit progress(p);
        }));
        connections->append(connect(extractTask, &ZipExtractionTask::error, this, [this, extractTask, connections](const QString &err) {
            emit updateFailed(err);
            extractTask->deleteLater();
            delete connections;
        }));
        connections->append(connect(extractTask, &ZipExtractionTask::finished, this, [this, extractTask, connections]() {
            emit progress(1.0);
            extractTask->deleteLater();
            delete connections;
        }));
        extractTask->start();
    }));
    task->startDownload(downloadList);
}