#include "zipextractiontask.h"

#include <QUrl>
#include <QDebug>
#include <mcpelauncher/zip_extractor.h>
#include <mcpelauncher/minecraft_extract_utils.h>
#include <mcpelauncher/apkinfo.h>
#include <sstream>
#include "versionmanager.h"
#include "supportedandroidabis.h"

ZipExtractionTask::ZipExtractionTask(QObject *parent) : QThread(parent) {
    connect(this, &QThread::started, this, &ZipExtractionTask::emitActiveChanged);
    connect(this, &QThread::finished, this, &ZipExtractionTask::emitActiveChanged);
}

bool ZipExtractionTask::setSourceUrls(QList<QUrl> const& urls) {
    QStringList list;
    for (auto&& url : urls) {
        if (!url.isLocalFile()) {
            return false;
        }
        list.append(url.toLocalFile());
    }
    setSources(list);
    return true;
}

static bool mergeDirsRecusive(QString from, QString to) {
    if (QDir(from).exists()) {
        if (!QDir(to).exists()) {
            qDebug() << "Moving " << from << " to " << to;
            if (QFile::rename(from, to)) {
                return true;
            }
            // Fallback to manual copy / move
        }
        if(!QDir(to).mkpath(".")) {
            qDebug() << "Failed to create directory " << to;
            throw std::runtime_error(QObject::tr("creating directory %1 failed").arg(to).toStdString());
        }
        qDebug() << "Merging " << from << " to " << to;
        for (auto&& item : QDir(from).entryList()) {
            auto f = from + "/" + item;
            auto t = to + "/" + item;
            qDebug() << "Checking " << f << " to " << t << " Isdir=" << QDir(f).exists() << " IsFile=" << QFile(f).exists();
            if (item == "." || item == "..") {
                continue;
            }
            mergeDirsRecusive(f, t);
        }
        return false;
    }
    if (QFile::exists(from)) {
        if(!QFile::rename(from, to)) {
            if(QFile::copy(from, to)) {
                QFile::remove(from);
            } else {
                qDebug() << "Failed to move file " << from << " to " << to;
                throw std::runtime_error(QObject::tr("moving file from %1 to %2 failed").arg(from).arg(to).toStdString());
            }
        }
    }
}

void ZipExtractionTask::run() {
    QTemporaryDir dir;//(m_tempTemplate);
    try {
        std::string path = dir.path().toStdString();
        ApkInfo apkInfo;
        apkInfo.versionCode = 0;
        for (auto && source : sources()) {
            ZipExtractor extractor (source.toStdString());
            extractor.extractTo(
                [&path](const char* filename, std::string& outName) -> bool {
                    if(filename[strlen(filename) - 1] == '/') {
                        return false; // Skip directories
                    }
                    outName = path + "/" + filename;
                    return true; // Extract all files
                },
                [this](size_t current, size_t max, ZipExtractor::FileHandle const&, size_t, size_t) {
                    emit progress((float)  current / max);
                }
            );
        }
        QString targetDir = m_targetDir;
        if (mergeDirsRecusive(dir.path(), targetDir)) {
            dir.setAutoRemove(false);
        }
    } catch (std::exception& e) {
        emit error(e.what());
        return;
    }
    emit finished();
}
