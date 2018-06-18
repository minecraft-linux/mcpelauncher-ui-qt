#include "apkextractiontask.h"

#include <QUrl>
#include <QDebug>
#include <fcntl.h>
#include <unistd.h>
#include <mcpelauncher/zip_extractor.h>
#include <mcpelauncher/minecraft_extract_utils.h>
#include <mcpelauncher/minecraft_elf_info.h>
#include "versionmanager.h"

ApkExtractionTask::ApkExtractionTask(QObject *parent) : QThread(parent) {
    connect(this, &QThread::started, this, &ApkExtractionTask::emitActiveChanged);
    connect(this, &QThread::finished, this, &ApkExtractionTask::emitActiveChanged);
}

bool ApkExtractionTask::setSourceUrl(const QUrl &url) {
    if (!url.isLocalFile())
        return false;
    setSource(url.toLocalFile());
    return true;
}

void ApkExtractionTask::run() {
    QTemporaryDir dir (versionManager()->getTempTemplate());
    int elfFd = -1;
    try {
        std::string path = dir.path().toStdString();

        ZipExtractor extractor (source().toStdString());
        extractor.extractTo(MinecraftExtractUtils::filterMinecraftFiles(path),
                [this](size_t current, size_t max, ZipExtractor::FileHandle const&, size_t, size_t) {
            emit progress((float)  current / max);
        });

        elfFd = open((path + "/libs/libminecraftpe.so").c_str(), O_RDONLY);
        if (elfFd < 0)
            throw std::runtime_error("Failed to open libminecraftpe.so");
        ElfReader<Elf32Types> elfReader (elfFd);
        MinecraftElfInfo elfInfo = MinecraftElfInfo::fromElf(elfReader);
        close(elfFd);

        QString targetDir = versionManager()->getDirectoryFor(elfInfo);
        qDebug() << "Moving " << dir.path() << " to " << targetDir;
        QDir(targetDir).removeRecursively();
        if (!QDir().rename(dir.path(), targetDir))
            throw std::runtime_error("rename failed");
        dir.setAutoRemove(false);
    } catch (std::exception& e) {
        if (elfFd != -1)
            close(elfFd);
        emit error(e.what());
        return;
    }

    emit finished();
}
