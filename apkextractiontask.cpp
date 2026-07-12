#include "apkextractiontask.h"

#include <QUrl>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QVariantMap>
#include <mcpelauncher/zip_extractor.h>
#include <mcpelauncher/minecraft_extract_utils.h>
#include <mcpelauncher/apkinfo.h>
#include <zlib.h>
#include <memory>
#include <sstream>
#include "versionmanager.h"
#include "supportedandroidabis.h"
#include "remotezipsource.h"

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

namespace {

struct ExistingFileMetadata {
    bool exists = false;
    size_t size = 0;
    zip_uint32_t crc = 0;
};

struct SourceContext {
    QString label;
    QString localPath;
    QVariantMap descriptor;
    bool isRemote = false;
    bool isBaseApk = false;
    std::unique_ptr<RemoteZipSource> remote;
    std::unique_ptr<ZipExtractor> extractor;
    std::vector<ZipExtractor::EntryInfo> entries;
};

struct PlannedEntry {
    size_t sourceIndex = 0;
    ZipExtractor::EntryInfo entry;
    QString oldPath;
    QString outputPath;
    bool shouldCopy = false;
};

static QString joinPath(QString const& base, std::string const& relative) {
    if (base.isEmpty())
        return QString::fromStdString(relative);
    return QDir(base).filePath(QString::fromStdString(relative));
}

static ExistingFileMetadata getExistingFileMetadata(QString const& path) {
    ExistingFileMetadata metadata;
    QFile file(path);
    if (!file.exists())
        return metadata;
    if (!file.open(QIODevice::ReadOnly))
        return metadata;
    metadata.exists = true;
    metadata.size = (size_t) file.size();
    metadata.crc = crc32(0L, Z_NULL, 0);
    char buf[8192];
    while (true) {
        auto bytesRead = file.read(buf, sizeof(buf));
        if (bytesRead < 0)
            return ExistingFileMetadata{};
        if (bytesRead == 0)
            break;
        metadata.crc = crc32(metadata.crc, reinterpret_cast<const Bytef*>(buf), (uInt) bytesRead);
    }
    return metadata;
}

static void emitUnifiedProgress(ApkExtractionTask* task, size_t completed, size_t total) {
    qreal value = total == 0 ? 1.0 : (qreal) completed / (qreal) total;
    QMetaObject::invokeMethod(task, "progress", Qt::DirectConnection, Q_ARG(qreal, value));
}

static void copyFileWithProgress(QString const& from, QString const& to, size_t totalSize,
                                 std::function<void(size_t)> const& onProgress) {
    QDir().mkpath(QFileInfo(to).dir().path());
    QFile src(from);
    QFile dst(to);
    if (!src.open(QIODevice::ReadOnly))
        throw std::runtime_error(QObject::tr("Failed to open source file %1").arg(from).toStdString());
    if (!dst.open(QIODevice::WriteOnly | QIODevice::Truncate))
        throw std::runtime_error(QObject::tr("Failed to open target file %1").arg(to).toStdString());

    char buf[8192];
    size_t copied = 0;
    onProgress(0);
    while (true) {
        auto bytesRead = src.read(buf, sizeof(buf));
        if (bytesRead < 0)
            throw std::runtime_error(QObject::tr("Failed to read source file %1").arg(from).toStdString());
        if (bytesRead == 0)
            break;
        if (dst.write(buf, bytesRead) != bytesRead)
            throw std::runtime_error(QObject::tr("Failed to write target file %1").arg(to).toStdString());
        copied += (size_t) bytesRead;
        onProgress(std::min(copied, totalSize));
    }
}

static std::vector<SourceContext> parseSources(QVariantList const& descriptors, QStringList const& fallbackSources) {
    std::vector<SourceContext> contexts;
    if (!descriptors.isEmpty()) {
        contexts.reserve(descriptors.size());
        for (auto const& item : descriptors) {
            auto descriptor = item.toMap();
            SourceContext context;
            context.descriptor = descriptor;
            context.label = descriptor.value("label").toString();
            context.localPath = descriptor.value("path").toString();
            context.isRemote = descriptor.value("type").toString() == "remote";
            contexts.push_back(std::move(context));
        }
        return contexts;
    }

    contexts.reserve(fallbackSources.size());
    for (auto const& source : fallbackSources) {
        SourceContext context;
        context.label = QFileInfo(source).fileName();
        context.localPath = source;
        contexts.push_back(std::move(context));
    }
    return contexts;
}

static std::unique_ptr<ZipExtractor> openExtractor(SourceContext& source) {
    if (!source.isRemote)
        return std::make_unique<ZipExtractor>(source.localPath.toStdString());

    auto headers = source.descriptor.value("headers").toMap();
    source.remote = std::make_unique<RemoteZipSource>(
            (size_t) source.descriptor.value("size").toULongLong(),
            source.descriptor.value("url").toString().toStdString(),
            headers.value("User-Agent").toString().toStdString(),
            headers.value("Cookie").toString().toStdString());
    return std::make_unique<ZipExtractor>(source.remote->create());
}

}

void ApkExtractionTask::run() {
    QTemporaryDir dir (versionManager()->getTempTemplate());
    try {
        QString tempPath = dir.path();
        ApkInfo apkInfo;
        apkInfo.versionCode = 0;
        auto contexts = parseSources(sourceDescriptors(), sources());
        std::vector<PlannedEntry> plan;
        size_t globalTotalSize = 0;

        for (size_t i = 0; i < contexts.size(); ++i) {
            auto& source = contexts[i];
            source.extractor = openExtractor(source);

            auto manifest = source.extractor->readFile("AndroidManifest.xml");
            axml::AXMLFile manifestFile(manifest.data(), manifest.size());
            axml::AXMLParser manifestParser(manifestFile);
            ApkInfo capkInfo = ApkInfo::fromXml(manifestParser);
            if (!apkInfo.versionCode) {
                apkInfo = capkInfo;
                if (!m_allowedPackages.empty() && !m_allowedPackages.contains(QString::fromStdString(apkInfo.package))) {
                    throw std::runtime_error(QObject::tr("Trying to import a forbidden apk").toStdString());
                }
            } else if (apkInfo.versionCode != capkInfo.versionCode) {
                throw std::runtime_error(QObject::tr("Trying to extract multiple apks with different versionsCodes is forbidden").toStdString());
            } else if (apkInfo.package != capkInfo.package) {
                throw std::runtime_error(QObject::tr("Trying to extract multiple apks with different package is forbidden").toStdString());
            } else if (apkInfo.versionName.empty()) {
                apkInfo.versionName = capkInfo.versionName;
            }
            source.isBaseApk = capkInfo.split.empty();
            source.entries = source.extractor->listEntries(MinecraftExtractUtils::filterMinecraftFiles("", source.isBaseApk));

            for (auto const& entry : source.entries) {
                PlannedEntry planned;
                planned.sourceIndex = i;
                planned.entry = entry;
                planned.outputPath = joinPath(tempPath, entry.outputName);
                if (!m_oldInstallationFolder.isEmpty()) {
                    planned.oldPath = joinPath(m_oldInstallationFolder, entry.outputName);
                    auto oldMetadata = getExistingFileMetadata(planned.oldPath);
                    planned.shouldCopy = oldMetadata.exists &&
                            oldMetadata.size == (size_t) entry.size &&
                            oldMetadata.crc == entry.crc;
                }
                plan.push_back(planned);
                globalTotalSize += (size_t) entry.size;
            }
        }

        qDebug() << "Apk info: versionCode=" << apkInfo.versionCode
                 << " versionName=" << QString::fromStdString(apkInfo.versionName);

        size_t globalCompletedSize = 0;
        emitUnifiedProgress(this, 0, globalTotalSize);

        for (auto const& planned : plan) {
            if (!planned.shouldCopy)
                continue;
            auto baseCompleted = globalCompletedSize;
            copyFileWithProgress(planned.oldPath, planned.outputPath, (size_t) planned.entry.size,
                                 [this, baseCompleted, globalTotalSize](size_t copied) {
                emitUnifiedProgress(this, baseCompleted + copied, globalTotalSize);
            });
            globalCompletedSize += (size_t) planned.entry.size;
        }

        for (size_t sourceIndex = 0; sourceIndex < contexts.size(); ++sourceIndex) {
            std::vector<ZipExtractor::EntryInfo> entriesToExtract;
            size_t sourceTotalSize = 0;
            for (auto const& planned : plan) {
                if (planned.sourceIndex != sourceIndex || planned.shouldCopy)
                    continue;
                auto entry = planned.entry;
                entry.outputName = planned.outputPath.toStdString();
                sourceTotalSize += (size_t) entry.size;
                entriesToExtract.push_back(std::move(entry));
            }
            if (entriesToExtract.empty())
                continue;

            auto baseCompleted = globalCompletedSize;
            contexts[sourceIndex].extractor->extractEntries(entriesToExtract,
                    [this, baseCompleted, globalTotalSize](size_t current, size_t, ZipExtractor::FileHandle const&, size_t, size_t) {
                emitUnifiedProgress(this, baseCompleted + current, globalTotalSize);
            });
            globalCompletedSize += sourceTotalSize;
        }
        emitUnifiedProgress(this, globalCompletedSize, globalTotalSize);

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
                if (contexts.size() == 1) {
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
            apkInfo.versionName = m_versionName.toStdString();
            m_versionName.clear();
        }
        if (apkInfo.versionName.empty()) {
            throw std::runtime_error(QObject::tr("unsupported, versionsname of the apk is empty").toStdString());
        }
        QString targetDir = versionManager()->getDirectoryFor(apkInfo.versionName);
        if (mergeDirsRecusive(tempPath, targetDir)) {
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
