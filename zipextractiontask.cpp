#include "zipextractiontask.h"

#include <QUrl>
#include <QDebug>
#include <mcpelauncher/zip_extractor.h>
#include <mcpelauncher/minecraft_extract_utils.h>
#include <mcpelauncher/apkinfo.h>
#include <sstream>
#include <fstream>
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
            QFile fDir{from};
            if (fDir.exists()) {
                fDir.remove();
            }
            qDebug() << "Moving " << from << " to " << to;
            if (QDir().rename(from, to) || QFile::rename(from, to)) {
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
    QFile f{from};
    if (f.exists()) {
        qDebug() << "Moving file " << from << " to " << to;
        QFile::remove(to);
        QDir(to).removeRecursively();
        if(!f.rename(to)) {
            qDebug() << "Failed to rename file " << from << " to " << to << " due to " << f.errorString() << ". Trying copy + delete.";
            if(!f.copy(to)) {
                qDebug() << "Failed to copy file " << from << " to " << to << " due to " << f.errorString() << ". Trying to use plain c++.";
                std::ifstream src(from.toStdString(), std::ios::binary);
                std::ofstream dst(to.toStdString(), std::ios::binary);
                dst << src.rdbuf();
                if(!src.good() || !dst.good()) {
                    throw std::runtime_error(QObject::tr("copying file from %1 to %2 failed").arg(from).arg(to).toStdString());
                }
            }
        }
    }
    return false;
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
