#include "apkextractiontask.h"

#include <QUrl>
#include <QDebug>
#include <mcpelauncher/zip_extractor.h>
#include <mcpelauncher/minecraft_extract_utils.h>
#include <mcpelauncher/apkinfo.h>
#include "versionmanager.h"

ApkExtractionTask::ApkExtractionTask(QObject *parent) : QThread(parent) {
    connect(this, &QThread::started, this, &ApkExtractionTask::emitActiveChanged);
    connect(this, &QThread::finished, this, &ApkExtractionTask::emitActiveChanged);
    connect(this, &ApkExtractionTask::versionInformationObtained, this, &ApkExtractionTask::onVersionInformationObtained);
}

bool ApkExtractionTask::setSourceUrl(const QUrl &url) {
    if (!url.isLocalFile())
        return false;
    setSource(url.toLocalFile());
    return true;
}

void ApkExtractionTask::run() {
    QTemporaryDir dir (versionManager()->getTempTemplate());
    try {
        std::string path = dir.path().toStdString();

        ZipExtractor extractor (source().toStdString());
        ApkInfo apkInfo;
        {
            auto manifest = extractor.readFile("AndroidManifest.xml");
            axml::AXMLFile manifestFile (manifest.data(), manifest.size());
            axml::AXMLParser manifestParser (manifestFile);
            apkInfo = ApkInfo::fromXml(manifestParser);
        }
        qDebug() << "Apk info: versionCode=" << apkInfo.versionCode
                 << " versionName=" << QString::fromStdString(apkInfo.versionName);

        extractor.extractTo(MinecraftExtractUtils::filterMinecraftFiles(path),
                [this](size_t current, size_t max, ZipExtractor::FileHandle const&, size_t, size_t) {
            emit progress((float)  current / max);
        });

        QString targetDir = versionManager()->getDirectoryFor(apkInfo.versionName);
        qDebug() << "Moving " << dir.path() << " to " << targetDir;
        QDir(targetDir).removeRecursively();
        if (!QDir().rename(dir.path(), targetDir))
            throw std::runtime_error("rename failed");
        dir.setAutoRemove(false);
        emit versionInformationObtained(QDir(targetDir).dirName(), QString::fromStdString(apkInfo.versionName), apkInfo.versionCode);
    } catch (std::exception& e) {
        emit error(e.what());
        return;
    }

    emit finished();
}

void ApkExtractionTask::onVersionInformationObtained(const QString &directory, const QString &versionName, int versionCode) {
    versionManager()->addVersion(directory, versionName, versionCode);
}
