#include "googleapkdownloadtask.h"
#include "googleplayapi.h"
#include "googleloginhelper.h"

GoogleApkDownloadTask::GoogleApkDownloadTask(QObject *parent) : QObject(parent), m_active(false) {
}

void GoogleApkDownloadTask::setPlayApi(GooglePlayApi *value) {
    Q_ASSERT(m_playApi == nullptr);
    m_playApi = value;
}

QString GoogleApkDownloadTask::filePath() {
    QMutexLocker l (&fileMutex);
    return file->fileName();
}

void GoogleApkDownloadTask::start() {
    m_active.store(true);
    emit activeChanged();
    m_playApi->getApi()->delivery(m_packageName.toStdString(), m_versionCode, std::string())->call([this](playapi::proto::finsky::response::ResponseWrapper&& resp) {
        auto dd = resp.payload().deliveryresponse().appdeliverydata();
        startGzippedDownload(dd);
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

void GoogleApkDownloadTask::startGzippedDownload(playapi::proto::finsky::download::AndroidAppDeliveryData const &dd) {
    QMutexLocker l (&fileMutex);
    if (!file)
        file.reset(new QTemporaryFile);
    playapi::http_request req(dd.gzippeddownloadurl());
    req.set_encoding("gzip,deflate");
    req.add_header("Accept-Encoding", "identity");
    auto cookie = dd.downloadauthcookie(0);
    req.add_header("Cookie", cookie.name() + "=" + cookie.value());
    auto& device = m_playApi->getLogin()->getDevice();
    req.set_user_agent("AndroidDownloadManager/" + device.build_version_string + " (Linux; U; Android " +
                       device.build_version_string + "; " + device.build_model + " Build/" + device.build_id + ")");
    req.set_follow_location(true);
    req.set_timeout(0L);

    if (!file->open())
        throw std::runtime_error("Failed to open file");
    int fd = file->handle();
    z_stream* zs = new z_stream;
    zs->zalloc = Z_NULL;
    zs->zfree = Z_NULL;
    zs->opaque = Z_NULL;
    int ret = inflateInit2(zs, 31);
    if (ret != Z_OK)
        throw std::runtime_error("Failed to init zlib");

    req.set_custom_output_func([fd, zs](char* data, size_t size) {
        if (!curlDoZlibInflate(*zs, fd, data, size, Z_NO_FLUSH))
            return (size_t) 0;
        return size;
    });

    req.set_progress_callback([this](curl_off_t dltotal, curl_off_t dlnow, curl_off_t ultotal, curl_off_t ulnow) {
        if (dltotal > 0)
            emit progress((float) dlnow / dltotal);
    });
    emit progress(0.f);
    req.perform([this, zs, fd](playapi::http_response resp) {
        QMutexLocker l (&fileMutex);
        curlDoZlibInflate(*zs, fd, Z_NULL, 0, Z_FINISH);
        inflateEnd(zs);
        file->close();

        if (resp)
            emit finished();
        else
            emit error("CURL error");
        m_active.store(false);
        emit activeChanged();
    }, [this, zs, fd](std::exception_ptr e) {
        curlDoZlibInflate(*zs, fd, Z_NULL, 0, Z_FINISH);
        inflateEnd(zs);
        file->close();

        try {
            std::rethrow_exception(e);
        } catch(std::exception& e) {
            emit error(e.what());
        }
        m_active.store(false);
        emit activeChanged();
    });
}
