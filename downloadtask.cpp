#include "downloadtask.h"
#include <QStandardPaths>
#include <QDir>
#ifdef GOOGLEPLAYDOWNLOADER_USEQT
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QtConcurrent>
#endif
#include <unistd.h>

DownloadDataWrapper::DownloadDataWrapper(QObject *parent)
    : QObject(parent) {}

QString DownloadDataWrapper::url() const {
    return m_url;
}

void DownloadDataWrapper::setUrl(const QString &value) {
    if (m_url != value) {
        m_url = value;
        emit urlChanged();
    }
}

QString DownloadDataWrapper::gzippedUrl() const {
    return m_gzippedUrl;
}

void DownloadDataWrapper::setGzippedUrl(const QString &value) {
    if (m_gzippedUrl != value) {
        m_gzippedUrl = value;
        emit gzippedUrlChanged();
    }
}

QString DownloadDataWrapper::cookie() const {
    return m_cookie;
}

void DownloadDataWrapper::setCookie(const QString &value) {
    if (m_cookie != value) {
        m_cookie = value;
        emit cookieChanged();
    }
}

QString DownloadDataWrapper::componentName() const {
    return m_componentName;
}

void DownloadDataWrapper::setComponentName(const QString &value) {
    if (m_componentName != value) {
        m_componentName = value;
        emit componentNameChanged();
    }
}

bool DownloadDataWrapper::isGzipped() const {
    return m_isGzipped;
}

void DownloadDataWrapper::setIsGzipped(bool value) {
    if (m_isGzipped != value) {
        m_isGzipped = value;
        emit isGzippedChanged();
    }
}

size_t DownloadDataWrapper::id() const {
    return m_id;
}

void DownloadDataWrapper::setId(size_t value) {
    if (m_id != value) {
        m_id = value;
        emit idChanged();
    }
}

size_t DownloadDataWrapper::downloadSize() const {
    return m_downloadSize;
}

void DownloadDataWrapper::setDownloadSize(size_t value) {
    if (m_downloadSize != value) {
        m_downloadSize = value;
        emit downloadSizeChanged();
    }
}

size_t DownloadDataWrapper::gzippedDownloadSize() const {
    return m_gzippedDownloadSize;
}

void DownloadDataWrapper::setGzippedDownloadSize(size_t value) {
    if (m_gzippedDownloadSize != value) {
        m_gzippedDownloadSize = value;
        emit gzippedDownloadSizeChanged();
    }
}

DownloadTask::DownloadTask(QObject *parent) : QObject(parent), m_active(false) {
#ifdef GOOGLEPLAYDOWNLOADER_USEQT
    connect(this, &DownloadTask::queueDownload, this, &DownloadTask::startDownload);
#endif
}

QStringList DownloadTask::filePaths() {
    QMutexLocker l (&fileMutex);
    QStringList list;
    for(auto&& file : files) {
        list.append(file->fileName());
    }
    return list;
}

void DownloadTask::start(bool skipMainApk) {
//     m_active.store(true);
//     emit activeChanged();
//     m_playApi->getApi()->delivery(m_packageName.toStdString(), m_versionCode, std::string())->call([this, skipMainApk](playapi::proto::finsky::response::ResponseWrapper&& resp) {
//         auto dd = resp.payload().deliveryresponse().appdeliverydata();
//         auto apkUrl = dd.isGzipped ? dd.gzippeddownloadurl() : dd.downloadurl();
//         if(apkUrl == "") {
//             throw std::runtime_error(QObject::tr("Cannot find <a href=\"https://play.google.com/store/apps/details?id=%1\">%1</a> with version %2 on Google Play,<br/><a href=\"https://play.google.com/apps/testing/%1\">Beta Versions requires sign up</a>%3").arg(m_packageName).arg(m_versionCode).arg(m_playApi->getLogin()->isChromeOS() ? QObject::tr(",<br/>you might want to try disabling ChromeOS mode to fix this") : "").toStdString());
//         }
//         if(m_dryrun) {
//             QString allUrls;
//             if (!skipMainApk || dd.splitdeliverydata().empty() /* Old Minecraft versions < 1.15.y needs a full download */) {
//                 auto url = dd.downloadurl();
//                 allUrls += QObject::tr("<a href=\"%2\">%1</a>: %2<br/>").arg("main").arg(QString::fromStdString(url));
//             }
//             for(auto && data : dd.splitdeliverydata()) {
//                 auto url = /*data.isGzipped ? data.gzippeddownloadurl() :*/ data.downloadurl();
//                 allUrls += QObject::tr("<a href=\"%2\">%1</a>: %2<br/>").arg(QString::fromStdString(data.id())).arg(QString::fromStdString(url));
//             }
//             emit downloadInfo(allUrls);
//             return;
//         }
//         bool isGzipped = dd.isGzipped;
//         std::vector<DownloadData> myd = {};
//         if (!skipMainApk || dd.splitdeliverydata().empty() /* Old Minecraft versions < 1.15.y needs a full download */) {
//             myd.emplace_back(isGzipped ? dd.gzippeddownloadurl() : dd.downloadurl(), dd.downloadauthcookie(0), std::make_shared<DownloadProgress>(), "main", isGzipped ? dd.gzippeddownloadsize() : dd.downloadsize());
//         }
//         for(auto && data : dd.splitdeliverydata()) {
//             isGzipped = data.isGzipped;
//             myd.emplace_back(isGzipped ? data.gzippeddownloadurl() : data.downloadurl(), data.downloadauthcookie(0), std::make_shared<DownloadProgress>(), data.id(), isGzipped ? data.gzippeddownloadsize() : data.downloadsize());
//         }
// #ifdef GOOGLEPLAYDOWNLOADER_USEQT
//         emit queueDownload(myd, skipMainApk);
// #else
//         startDownload(myd, skipMainApk);
// #endif
//     }, [this](std::exception_ptr e) {
//         try {
//             std::rethrow_exception(e);
//         } catch(std::exception& e) {
//             emit error(e.what());
//         }
//         m_active.store(false);
//         emit activeChanged();
//     });
}

bool DownloadTask::curlDoZlibInflate(z_stream &zs, int file, char *data, size_t len, int flags) {
    char buf[4096];
    int ret;
    zs.avail_in = (uInt) len;
    zs.next_in = (unsigned char*) data;
    zs.avail_out = 0;
    while (zs.avail_out == 0) {
        zs.avail_out = 4096;
        zs.next_out = (unsigned char*) buf;
        ret = inflate(&zs, flags);
        if (ret == Z_STREAM_ERROR)
            return false;
        if (write(file, buf, sizeof(buf) - zs.avail_out) != sizeof(buf) - zs.avail_out)
            return false;
    }
    return true;
}

void DownloadTask::downloadFile(DownloadData const&dd, std::function<void()> success, std::function<void()> _error, std::shared_ptr<DownloadProgress> _progress, std::string componentName, size_t id) {
    auto apkUrl = dd.isGzipped ? dd.gzippedUrl : dd.url;
    emit downloadInfo(QString::fromStdString(apkUrl));
    if(m_dryrun) {
        std::thread(success).detach();
        return;
    }
    auto apksdir = QDir(QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)).filePath("mcpelauncher/downloads");
    QDir().mkpath(apksdir);
    auto file = std::make_shared<QTemporaryFile>(QDir(apksdir).filePath(/*m_keepDownload ? (m_packageName.toStdString() + "-" + componentName + "-XXXXXX.apk").data() :*/ "temp-XXXXXX.zip"));
    if(m_keepDownload) {
        file->setAutoRemove(false);
    }
#ifdef GOOGLEPLAYDOWNLOADER_USEQT
    file->open();
    auto url = dd.url;
    {
        if(_progress->downloadsize != -1) {
            auto size = dd.downloadSize;
            if(size > 0) {
                _progress->downloadsize += size;
                _progress->progress[id] = 0;
            } else {
                _progress->downloadsize = -1;
            }
        }
    }
    QNetworkAccessManager* manager = new QNetworkAccessManager(this);
    QNetworkRequest request;
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    request.setUrl(QUrl(QString::fromStdString(url)));
    connect(manager, &QNetworkAccessManager::finished, [file, this, manager, success, _error, url](QNetworkReply* reply) {
        file->flush();
        file->close();
        if(!reply->error()) {
            {
                QMutexLocker l (&fileMutex);
                files.push_back(file);
            }
            success();
        } else {
            emit error(QObject::tr("Downloading file failed %1").arg(QString::fromStdString(url)));
            _error();
        }
        reply->deleteLater();
        manager->deleteLater();
    });
    auto reply = manager->get(request);
    connect(reply, &QNetworkReply::readyRead, [reply, file]() {
        file->write(reply->readAll());
    });
    connect(reply, &QNetworkReply::downloadProgress, [_progress, id, this](qint64 dlnow, qint64 total) {
        if(_progress->downloadsize > 0) {
            _progress->progress[id] = dlnow;
            emit progress((float) std::accumulate(_progress->progress.begin(), _progress->progress.end(), 0) / _progress->downloadsize);
        }
    });
#else
    bool isGzipped = dd.isGzipped;
    playapi::http_request req(isGzipped ? dd.gzippedUrl : dd.url);
    // The http method has been undefined behavior
    req.set_method(playapi::http_method::GET);
    if(_progress->downloadsize != -1) {
        auto size = isGzipped ? dd.gzippedDownloadSize : dd.downloadSize;
        if(size > 0) {
            _progress->downloadsize += size;
            _progress->progress[id] = 0;
        } else {
            _progress->downloadsize = -1;
        }
    }
    if (isGzipped)
        req.set_encoding("gzip,deflate");
    req.add_header("Accept-Encoding", "identity");
    if(dd.cookie != "") {
        req.add_header("Cookie", dd.cookie);
    }
    // auto& device = m_playApi->getLogin()->getDevice();
    // req.set_user_agent("AndroidDownloadManager/" + device.build_version_string + " (Linux; U; Android " +
    //                    device.build_version_string + "; " + device.build_model + " Build/" + device.build_id + ")");
    req.set_follow_location(true);
    req.set_timeout(0L);

    if (!file->open())
        throw std::runtime_error("Failed to open file");
    int fd = file->handle();
    std::shared_ptr<z_stream> zs;
    if (isGzipped) {
        zs = std::make_shared<z_stream>();
        zs->zalloc = Z_NULL;
        zs->zfree = Z_NULL;
        zs->opaque = Z_NULL;
        int ret = inflateInit2(zs.get(), 31);
        if (ret != Z_OK)
            throw std::runtime_error("Failed to init zlib");

        req.set_custom_output_func([fd, zs](char* data, size_t size) {
            if (!curlDoZlibInflate(*zs, fd, data, size, Z_NO_FLUSH))
                return (size_t) 0;
            return size;
        });
    } else {
        req.set_custom_output_func([fd](char* data, size_t size) {
            return write(fd, data, size);
        });
    }

    req.set_progress_callback([this, _progress, id](curl_off_t dltotal, curl_off_t dlnow, curl_off_t ultotal, curl_off_t ulnow) {
        std::lock_guard<std::mutex> guard(_progress->mtx);
        if(_progress->downloadedSizes[id] < dltotal) {
            _progress->downloadedSizes[id] = dltotal;
            auto nsize = std::accumulate(_progress->downloadedSizes.begin(), _progress->downloadedSizes.end(), 0);
            if(nsize > _progress->downloadsize) {
                _progress->downloadsize = nsize;
            }
        }
        if(_progress->downloadsize > 0) {
            _progress->progress[id] = dlnow;
            emit progress((float) std::accumulate(_progress->progress.begin(), _progress->progress.end(), 0) / _progress->downloadsize);
        }
    });
    emit progress(0.f);
    req.perform([this, file, zs, fd, isGzipped, success, _error](playapi::http_response resp) {
        if (isGzipped) {
            curlDoZlibInflate(*zs, fd, Z_NULL, 0, Z_FINISH);
            inflateEnd(zs.get());
        }
        file->close();
        if (resp) {
            if(resp.get_status_code() == 200) {
                {
                    QMutexLocker l (&fileMutex);
                    files.push_back(file);
                }
                success();
            } else {
                emit error(QObject::tr("Downloading file failed: Status[%1] '%2'").arg(QString::fromStdString(std::to_string(resp.get_status_code()))).arg(QString::fromStdString(resp.get_body())));
                _error();
            }
        }
        else {
            emit error(QObject::tr("CURL Network error: %1").arg(QObject::tr("Unknown error")));
            _error();
        }
    }, [this, file, zs, fd, isGzipped, _error](std::exception_ptr e) {
        if (isGzipped) {
            curlDoZlibInflate(*zs, fd, Z_NULL, 0, Z_FINISH);
            inflateEnd(zs.get());
        }
        file->close();

        try {
            std::rethrow_exception(e);
        } catch(std::exception& e) {
            emit error(e.what());
        }
        _error();
    });
#endif
}

void DownloadTask::startDownload(std::vector<DownloadData> const& dd) {
    auto progress = std::make_shared<DownloadProgress>();
    std::lock_guard<std::mutex> guard(progress->mtx);
    progress->downloads = dd.size();
    progress->progress.resize(progress->downloads);
    progress->downloadedSizes.resize(progress->downloads);
    progress->downloadsize = 0;
    auto cleanup = [this, progress]() {
        std::lock_guard<std::mutex> guard(progress->mtx);
        if(!--progress->downloads) {
            m_active.store(false);
            emit activeChanged();
        }
    };
    auto success = [this, cleanup, progress]() {
        std::lock_guard<std::mutex> guard(progress->mtx);
        if(!--progress->downloads) {
            m_active.store(false);
            emit activeChanged();
            emit finished();
        }
    };
    {
        QMutexLocker l (&fileMutex);
        files.clear();
    }
    size_t id = 0;
    for(auto && data : dd) {
        downloadFile(data, success, cleanup, progress, data.componentName, id++);
    }
    progress->downloads = id;
}

void DownloadTask::startDownload(const QList<DownloadDataWrapper*> &downloadList) {
    m_active.store(true);
    emit activeChanged();
    std::vector<DownloadData> dd;
    for(auto && data : downloadList) {
        dd.push_back(data->toNative());
    }
#ifdef GOOGLEPLAYDOWNLOADER_USEQT
    emit queueDownload(dd);
#else
    startDownload(dd);
#endif
}
