#include "apkextractiontask.h"

#include <QUrl>
#include <mcpelauncher/zip_extractor.h>
#include <mcpelauncher/minecraft_extract_utils.h>

ApkExtractionTask::ApkExtractionTask(QObject *parent) : QThread(parent){
}

bool ApkExtractionTask::setSourceUrl(const QUrl &url) {
    if (!url.isLocalFile())
        return false;
    setSource(url.toLocalFile());
    return true;
}

void ApkExtractionTask::run() {
    try {
        ZipExtractor extractor (source().toStdString());
        extractor.extractTo(MinecraftExtractUtils::filterMinecraftFiles(destination().toStdString()),
                [this](size_t current, size_t max, ZipExtractor::FileHandle const&, size_t, size_t) {
            emit progress((float)  current / max);
        });
        emit finished();
    } catch (ZipExtractionError& e) {
        emit error(e.what());
    }
}
