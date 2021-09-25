#include "googleapkdownloadtask.h"
#include "googleplayapi.h"
#include "googleloginhelper.h"
#ifdef GOOGLEPLAYDOWNLOADER_USECURL
#include <curl/curl.h>
#include <curl/easy.h>
#include <functional>
#endif

GoogleApkDownloadTask::GoogleApkDownloadTask(QObject *parent) : QObject(parent), m_active(false) {
}

void GoogleApkDownloadTask::setPlayApi(GooglePlayApi *value) {
    Q_ASSERT(m_playApi == nullptr);
    m_playApi = value;
}

QStringList GoogleApkDownloadTask::filePaths() {
    QMutexLocker l (&fileMutex);
    QStringList list;
    for(auto&& file : files) {
        list.append(file->fileName());
    }
    return list;
}

void GoogleApkDownloadTask::start(bool skipMainApk) {
    m_active.store(true);
    emit activeChanged();
    m_playApi->getApi()->delivery(m_packageName.toStdString(), m_versionCode, std::string())->call([this, skipMainApk](playapi::proto::finsky::response::ResponseWrapper&& resp) {
        auto dd = resp.payload().deliveryresponse().appdeliverydata();
        if((dd.has_gzippeddownloadurl() ? dd.gzippeddownloadurl() : dd.downloadurl()) == "") {
            throw std::runtime_error(QObject::tr("To use the download feature, <a href=\"https://play.google.com/store/apps/details?id=com.mojang.minecraftpe\">Minecraft: Bedrock Edition has to be purchased on the Google Play Store</a>.<br>If you are trying to download a beta version, please make sure you are in the <a href=\"https://play.google.com/apps/testing/com.mojang.minecraftpe\">Minecraft beta program on Google Play.</a> and then try again after a while (joining the program might take a while).").toStdString());
        }
        startDownload(dd, skipMainApk);
    }, [this](std::exception_ptr e) {
        try {
            std::rethrow_exception(e);
        } catch(std::exception& e) {
            emit error(e.what());
        }
        m_active.store(false);
        emit activeChanged();
    });
}

bool GoogleApkDownloadTask::curlDoZlibInflate(z_stream &zs, int file, char *data, size_t len, int flags) {
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

template<class T, class U> void GoogleApkDownloadTask::downloadFile(T const&dd, U cookie, std::function<void()> success, std::function<void()> _error, std::shared_ptr<DownloadProgress> _progress, size_t id) {
#ifdef GOOGLEPLAYDOWNLOADER_USECURL
    auto url = dd.downloadurl();
    {
        std::lock_guard<std::mutex> guard(_progress->mtx);
        if(_progress->downloadsize != -1) {
            auto size = dd.downloadsize();
            if(size > 0) {
                _progress->downloadsize += size;
                _progress->progress[id] = 0;
            } else {
                _progress->downloadsize = -1;
            }
        }
    }
    std::thread([this, success, _error, _progress, id]() {
        auto file = std::make_shared<QTemporaryFile>();
        if (!file->open())
            throw std::runtime_error("Failed to open file");
        int fd = file->handle();

        /* init the curl session */
        auto curl_handle = curl_easy_init();
        
        /* set URL to get here */
        curl_easy_setopt(curl_handle, CURLOPT_URL, url.data());
        
        /* enable progress meter, set to 1L to disable it */
        curl_easy_setopt(curl_handle, CURLOPT_NOPROGRESS, 0L);
        
        /* send all data to this function  */
        curl_easy_setopt(curl_handle, CURLOPT_WRITEFUNCTION, [](void *ptr, size_t size, size_t nmemb, void *stream) -> size_t {
            return write(*(int*)stream, ptr, size * nmemb);
        });

        curl_easy_setopt(curl_handle, CURLOPT_FOLLOWLOCATION, 1L);

        std::function<void(size_t)> progresscallback = [this, id, _progress](size_t dlnow) {
            std::lock_guard<std::mutex> guard(_progress->mtx);
            if(_progress->downloadsize > 0) {
                _progress->progress[id] = dlnow;
                emit progress((float) std::accumulate(_progress->progress.begin(), _progress->progress.end(), 0) / _progress->downloadsize);
            }
        };
        curl_easy_setopt(curl_handle, CURLOPT_XFERINFOFUNCTION, [](void *clientp,   curl_off_t dltotal,   curl_off_t dlnow,   curl_off_t ultotal,   curl_off_t ulnow) -> int {
            (*(std::function<void(size_t)>*)clientp)(dlnow);
            return CURL_PROGRESSFUNC_CONTINUE;
        });

        curl_easy_setopt(curl_handle, CURLOPT_XFERINFODATA, &progresscallback);

        /* write the page body to this file handle */
        curl_easy_setopt(curl_handle, CURLOPT_WRITEDATA, &fd);
        
        char errormsg[CURL_ERROR_SIZE];
        curl_easy_setopt(curl_handle, CURLOPT_ERRORBUFFER, errormsg);

        /* get it! */
        auto res = curl_easy_perform(curl_handle);

        file->close();
        if(res == CURLE_OK) {
            long response_code;
            curl_easy_getinfo(curl_handle, CURLINFO_RESPONSE_CODE, &response_code);
            if(response_code == 200) {
                {
                    QMutexLocker l (&fileMutex);
                    files.push_back(file);
                }
                success();
            } else {
                emit error(QObject::tr("Downloading file failed: Status %1").arg(QString::fromStdString(std::to_string(response_code))));
                _error();
            }
        } else {
            auto len = strlen(errormsg);
            emit error(QObject::tr("CURL Network error: %1").arg(len ? errormsg : QObject::tr("Unknown error")));
            _error();
        }

        /* cleanup curl stuff */
        curl_easy_cleanup(curl_handle);
    }).detach();
#else
    auto file = std::make_shared<QTemporaryFile>();
    bool isGzipped = dd.has_gzippeddownloadurl();
    playapi::http_request req(isGzipped ? dd.gzippeddownloadurl() : dd.downloadurl());
    if(_progress->downloadsize != -1) {
        auto size = isGzipped ? dd.gzippeddownloadsize() : dd.downloadsize();
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
    req.add_header("Cookie", cookie.name() + "=" + cookie.value());
    auto& device = m_playApi->getLogin()->getDevice();
    req.set_user_agent("AndroidDownloadManager/" + device.build_version_string + " (Linux; U; Android " +
                       device.build_version_string + "; " + device.build_model + " Build/" + device.build_id + ")");
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
        if(_progress->downloadsize > 0) {
            _progress->progress[id] = dlnow;
            emit progress((float) std::accumulate(_progress->progress.begin(), _progress->progress.end(), 0) / _progress->downloadsize);
        }
    });
    emit progress(0.f);
    struct ErrorBuffer {
        CURL * handle;
        char errormsg[CURL_ERROR_SIZE];
    };
    auto errorbuf = std::make_shared<ErrorBuffer>();
    errorbuf->handle = req.perform([this, file, zs, fd, isGzipped, success, _error, errorbuf](playapi::http_response resp) {
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
            auto len = strlen(errorbuf->errormsg);
            emit error(QObject::tr("CURL Network error: %1").arg(len ? errorbuf->errormsg : QObject::tr("Unknown error")));
            _error();
        }
    }, [this, file, zs, fd, isGzipped, _error, errorbuf](std::exception_ptr e) {
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
    curl_easy_setopt(errorbuf->handle, CURLOPT_ERRORBUFFER, errorbuf->errormsg);
#endif
}

void GoogleApkDownloadTask::startDownload(playapi::proto::finsky::download::AndroidAppDeliveryData const &dd, bool skipMainApk) {
    auto cookie = dd.downloadauthcookie(0);
    auto progress = std::make_shared<DownloadProgress>();
    std::lock_guard<std::mutex> guard(progress->mtx);
    progress->downloads = 1 + dd.splitdeliverydata().Capacity();
    progress->progress.resize(progress->downloads);
    progress->downloadsize = 0;
    auto cleanup = [this, progress]() {
        std::lock_guard<std::mutex> guard(progress->mtx);
        if(!--progress->downloads) {
            m_active.store(false);
            emit activeChanged();
        }
    };
    auto success = [this, cleanup, dd, cookie, progress]() {
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
    if (!skipMainApk || dd.splitdeliverydata().empty() /* Old Minecraft versions < 1.15.y needs a full download */) {
        downloadFile(dd, cookie, success, cleanup, progress, id++);
    }
    for(auto && data : dd.splitdeliverydata()) {
        downloadFile(data, cookie, success, cleanup, progress, id++);
    }
    progress->downloads = id;
}
