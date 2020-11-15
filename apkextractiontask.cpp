#include "apkextractiontask.h"

#include <QUrl>
#include <QDebug>
#include <mcpelauncher/zip_extractor.h>
#include <mcpelauncher/minecraft_extract_utils.h>
#include <mcpelauncher/apkinfo.h>
#include <sstream>
#include "versionmanager.h"
#include "supportedandroidabis.h"

ApkExtractionTask::ApkExtractionTask(QObject *parent) : QThread(parent) {
    connect(this, &QThread::started, this, &ApkExtractionTask::emitActiveChanged);
    connect(this, &QThread::finished, this, &ApkExtractionTask::emitActiveChanged);
    connect(this, &ApkExtractionTask::versionInformationObtained, this, &ApkExtractionTask::onVersionInformationObtained);
}

bool ApkExtractionTask::setSourceUrls(QList<QUrl> const& urls) {
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
    if (!QDir(to).exists()) {
        qDebug() << "Moving " << from << " to " << to;
        if (!QDir().rename(from, to))
            throw std::runtime_error(QObject::tr("renaming versionsfolder failed").toStdString());
        return true;
    } else {
        qDebug() << "Merging " << from << " to " << to;
        for (auto&& item : QDir(from).entryList()) {
            auto f = from + "/" + item;
            auto t = to + "/" + item;
            qDebug() << "Checking " << f << " to " << t << " Isdir=" << QDir(f).exists() << " IsFile=" << QFile(f).exists();
            if (item == "." || item == "..") {
                continue;
            }
            if (QDir(f).exists()) {
                mergeDirsRecusive(f, t);
            } else if (QFile(f).exists()) {
                QFile().rename(f, t);
            }
        }
        return false;
    }
}

void ApkExtractionTask::run() {
    QTemporaryDir dir (versionManager()->getTempTemplate());
    try {
        std::string path = dir.path().toStdString();
        ApkInfo apkInfo;
        apkInfo.versionCode = 0;
        for (auto && source : sources()) {
            ZipExtractor extractor (source.toStdString());
            {
                auto manifest = extractor.readFile("AndroidManifest.xml");
                axml::AXMLFile manifestFile (manifest.data(), manifest.size());
                axml::AXMLParser manifestParser (manifestFile);
                ApkInfo capkInfo = ApkInfo::fromXml(manifestParser);
                if (!apkInfo.versionCode) {
                    apkInfo = capkInfo;
                } else if(apkInfo.versionCode != capkInfo.versionCode) {
                    throw std::runtime_error(QObject::tr("Trying to extract multiple apks with different versionsCodes is forbidden").toStdString());
                } else if(apkInfo.versionName.empty()) {
                    apkInfo.versionName = capkInfo.versionName;
                }
            }
            qDebug() << "Apk info: versionCode=" << apkInfo.versionCode
                    << " versionName=" << QString::fromStdString(apkInfo.versionName);

            extractor.extractTo(MinecraftExtractUtils::filterMinecraftFiles(path),
                    [this](size_t current, size_t max, ZipExtractor::FileHandle const&, size_t, size_t) {
                emit progress((float)  current / max);
            });
        }

        bool supported = false;
        bool invalidapk = true;
        std::stringstream errormsg;
        for (auto &&abi : SupportedAndroidAbis::getAbis()) {
            if (QFile(dir.path() + "/lib/" + QString::fromStdString(abi.first) + "/libminecraftpe.so").exists()) {
                invalidapk = false;
                if (!abi.second.compatible) {
                    errormsg << QObject::tr("This Launcher cannot load Minecraft (%1) on this PC:<br/>%2<br/>").arg(QString::fromStdString(abi.second.details)).arg(QString::fromStdString(abi.second.details)).toStdString();
                } else {
                    supported = true;
                }
            }
        }
        if (!m_allowIncompatible && !supported) {
            if (invalidapk) {
                if (sources().size() == 1) {
                    errormsg << QObject::tr("The specified file is not a valid Minecraft apk, it doesn't contain libminecraftpe.so").toStdString();
                } else {
                    errormsg << QObject::tr("The specified files are not a valid collection of Minecraft apks, they don't contain libminecraftpe.so").toStdString();
                }
            }
            int i = 0;
            for (auto &&abi : SupportedAndroidAbis::getAbis()) {
                if (abi.second.compatible) {
                    if (i++) {
                        errormsg << ", ";
                    } else {
                        errormsg << "<br/>" << QObject::tr("Valid Minecraft apk CPU architectures for this pc / launcher are ").toStdString();
                    }
                    errormsg << abi.first;
                }
            }
            if (!i) {
                errormsg << "<br/>" << QObject::tr("No Minecraft apk's are valid for this pc / launcher").toStdString();
            }
            errormsg << "<br/>";
            throw std::runtime_error(errormsg.str());
        }

        if (!m_versionName.isEmpty()) {
            if (!apkInfo.versionName.empty()) {
                throw std::runtime_error(QObject::tr("unsupported, versionsname of the apk isn't empty, but property versionsName is set").toStdString());
            }
            apkInfo.versionName = m_versionName.toStdString();
            m_versionName.clear();
        }
        if (apkInfo.versionName.empty()) {
            throw std::runtime_error(QObject::tr("unsupported, versionsname of the apk is empty").toStdString());
        }
        QString targetDir = versionManager()->getDirectoryFor(apkInfo.versionName);
        if (mergeDirsRecusive(dir.path(), targetDir)) {
            dir.setAutoRemove(false);
        }
        emit versionInformationObtained(QDir(targetDir).dirName(), QString::fromStdString(apkInfo.versionName), apkInfo.versionCode);
    } catch (std::exception& e) {
        m_versionName.clear();
        emit error(e.what());
        return;
    }
    m_versionName.clear();
    
    emit finished();
}

void ApkExtractionTask::onVersionInformationObtained(const QString &directory, const QString &versionName, int versionCode) {
    versionManager()->addVersion(directory, versionName, versionCode);
}
