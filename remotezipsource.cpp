#include "remotezipsource.h"

#include <playapi/util/http.h>

#include <QDebug>

#include <algorithm>
#include <chrono>
#include <cerrno>
#include <cstring>
#include <fcntl.h>
#include <stdexcept>
#include <sstream>
#include <unistd.h>

RemoteZipSource::RemoteZipSource(size_t size, std::string url, std::string userAgent, std::string cookie)
    : m_size(size), m_url(std::move(url)), m_userAgent(std::move(userAgent)), m_cookie(std::move(cookie)) {
    zip_error_init(&m_lastError);
}

RemoteZipSource::~RemoteZipSource() {
    stopWorker();
    zip_error_fini(&m_lastError);
}

void RemoteZipSource::clearError() {
    std::lock_guard<std::mutex> lock(m_errorMutex);
    m_hasError = false;
    m_lastErrorMessage.clear();
    zip_error_set(&m_lastError, ZIP_ER_OK, 0);
}

void RemoteZipSource::setError(int zipError, int sysError, std::string const& message) {
    std::lock_guard<std::mutex> lock(m_errorMutex);
    m_hasError = true;
    m_lastErrorMessage = message;
    zip_error_set(&m_lastError, zipError, sysError);
}

void RemoteZipSource::stopWorker() {
    m_cancelWorker.store(true);
    if (m_readFd >= 0) {
        close(m_readFd);
        m_readFd = -1;
    }
    if (m_worker.joinable())
        m_worker.join();
}

void RemoteZipSource::startWorker() {
    clearError();
    m_cancelWorker.store(false);
    int pair[] = {0, 0};
    if (pipe(pair) != 0)
        throw std::runtime_error("pipe failed");
    m_readFd = pair[0];
    int writeFd = pair[1];
    const auto startOffset = m_offset;
#ifdef F_SETNOSIGPIPE
    fcntl(writeFd, F_SETNOSIGPIPE, 1);
#endif
    qDebug() << "RemoteZipSource: start worker"
             << "offset=" << startOffset
             << "size=" << m_size;
    m_worker = std::thread([this, writeFd](uint64_t start) {
        size_t bytesWritten = 0;
        unsigned retryCount = 0;
        while (!m_cancelWorker.load()) {
            const auto currentStart = start + bytesWritten;
            playapi::http_request req(m_url);
            const auto rangeHeader = (std::stringstream() << "bytes=" << currentStart << "-").str();
            req.set_method(playapi::http_method::GET);
            req.add_header("Accept-Encoding", "identity");
            req.add_header("Cookie", m_cookie);
            req.add_header("User-Agent", m_userAgent);
            req.add_header("Range", rangeHeader);
            req.set_follow_location(true);
            req.set_timeout(100L);
            req.set_connect_timeout(15L);
            req.set_low_speed_limit(1024L);
            req.set_low_speed_time(20L);
            req.set_custom_output_func([this, writeFd, &bytesWritten](char* data, size_t size) {
                ssize_t written = write(writeFd, data, size);
                if (written > 0) {
                    bytesWritten += static_cast<size_t>(written);
                    return static_cast<size_t>(written);
                }
                if (!m_cancelWorker.load()) {
                    setError(ZIP_ER_READ, errno, std::string("Remote ZIP pipe write failed: ") + strerror(errno));
                }
                return size_t(0);
            });
            try {
                qDebug() << "RemoteZipSource: HTTP GET" << QString::fromStdString(rangeHeader)
                         << "retry=" << retryCount;
                auto response = req.perform();
                qDebug() << "RemoteZipSource: HTTP completed: "
                         << "start=" << currentStart
                         << "status=" << response.get_status_code()
                         << "bytesWritten=" << bytesWritten;
                if ((currentStart > 0 && response.get_status_code() != 206) ||
                    (currentStart == 0 && response.get_status_code() != 200 && response.get_status_code() != 206)) {
                    std::stringstream err;
                    err << "Unexpected HTTP status " << response.get_status_code() << " for range " << rangeHeader;
                    setError(ZIP_ER_READ, 0, err.str());
                } else {
                    clearError();
                    break;
                }
            } catch (std::exception const& e) {
                if (!m_cancelWorker.load()) {
                    setError(ZIP_ER_READ, 0, e.what());
                    qDebug() << "RemoteZipSource: HTTP request threw"
                             << "start=" << currentStart
                             << "retry=" << retryCount
                             << e.what();
                }
            } catch (...) {
                if (!m_cancelWorker.load()) {
                    setError(ZIP_ER_READ, 0, "Unknown remote ZIP request failure");
                    qDebug() << "RemoteZipSource: HTTP request threw unknown exception"
                             << "start=" << currentStart
                             << "retry=" << retryCount;
                }
            }
            if (m_cancelWorker.load()) {
                break;
            }
            ++retryCount;
            auto delay = std::min<unsigned>(retryCount, 5U);
            std::this_thread::sleep_for(std::chrono::seconds(delay));
        }
        qDebug() << "RemoteZipSource: closing write pipe"
                 << "start=" << start;
        close(writeFd);
    }, startOffset);
}

zip_source_t* RemoteZipSource::create() {
    return zip_source_function_create(&RemoteZipSource::callback, this, nullptr);
}

zip_int64_t RemoteZipSource::callback(void *context, void *data, zip_uint64_t len, zip_source_cmd_t cmd) {
    auto* source = static_cast<RemoteZipSource*>(context);
    switch (cmd) {
    case ZIP_SOURCE_OPEN:
        source->clearError();
        return 0;
    case ZIP_SOURCE_CLOSE:
        source->stopWorker();
        return 0;
    case ZIP_SOURCE_ERROR: {
        std::lock_guard<std::mutex> lock(source->m_errorMutex);
        if (!source->m_hasError)
            return 0;
        qDebug() << "RemoteZipSource: ZIP_SOURCE_ERROR" << QString::fromStdString(source->m_lastErrorMessage);
        return zip_error_to_data(&source->m_lastError, data, len);
    }
    case ZIP_SOURCE_STAT: {
        auto* st = static_cast<zip_stat_t*>(data);
        st->size = source->m_size;
        st->comp_size = 0;
        st->mtime = 0;
        st->crc = 0;
        st->comp_method = 0;
        st->encryption_method = 0;
        st->flags = 0;
        st->valid = ZIP_STAT_SIZE;
        return sizeof(zip_stat_t);
    }
    case ZIP_SOURCE_READ: {
        bool worker_started = false;
        while (source->m_worker.joinable() &&
               source->m_offset < source->m_pendingSeek &&
               source->m_pendingSeek < source->m_offset + 0x100000) {
            size_t remaining = source->m_pendingSeek - source->m_offset;
            char buf[0x1000];
            int r = read(source->m_readFd, buf, std::min(sizeof(buf), remaining));
            if (r <= 0) {
                qDebug() << "RemoteZipSource: seek-drain read failed"
                         << "r=" << r
                         << "errno=" << errno
                         << strerror(errno)
                         << "offset=" << source->m_offset
                         << "pending=" << source->m_pendingSeek
                         << "remaining=" << remaining;
                return r;
            }
            source->m_offset += (size_t) r;
        }
        if (!source->m_worker.joinable() || source->m_pendingSeek != source->m_offset) {
            qDebug() << "RemoteZipSource: restart worker"
                     << "joinable=" << source->m_worker.joinable()
                     << "offset=" << source->m_offset
                     << "pending=" << source->m_pendingSeek;
            source->m_offset = source->m_pendingSeek;
            if (source->m_worker.joinable()) {
                source->m_cancelWorker.store(true);
                close(source->m_readFd);
                source->m_readFd = -1;
                source->m_worker.join();
            }
            source->startWorker();
            worker_started = true;
        }
        ssize_t r = read(source->m_readFd, data, len);
        if(r == 0) {
            if (source->m_worker.joinable()) {
                source->m_worker.join();
            }
            {
                std::lock_guard<std::mutex> lock(source->m_errorMutex);
                if (source->m_hasError) {
                    qDebug() << "RemoteZipSource: main read reached EOF after worker failure"
                             << QString::fromStdString(source->m_lastErrorMessage);
                    return -1;
                }
            }
            if(!worker_started && source->m_offset < source->m_size) {
                qDebug() << "RemoteZipSource: main read returned unexpected EOF"
                         << "offset=" << source->m_offset
                         << "pending=" << source->m_pendingSeek
                         << "len=" << len;
                source->setError(ZIP_ER_READ, 0, "Unexpected EOF while reading remote ZIP source");
                return -1;
            }
            return 0;
        }
        if (r <= 0) {
            qDebug() << "RemoteZipSource: main read returned"
                     << "r=" << r
                     << "errno=" << errno
                     << strerror(errno)
                     << "offset=" << source->m_offset
                     << "pending=" << source->m_pendingSeek
                     << "len=" << len;
        }
        if (r > 0) {
            source->m_offset += static_cast<size_t>(r);
            source->m_pendingSeek += static_cast<size_t>(r);
        }
        return r;
    }
    case ZIP_SOURCE_SEEK: {
        zip_source_args_seek_t *args = ZIP_SOURCE_GET_ARGS(zip_source_args_seek_t, data, len, nullptr);
        switch (args->whence) {
        case SEEK_SET:
            source->m_pendingSeek = args->offset;
            break;
        case SEEK_CUR:
            source->m_pendingSeek += args->offset;
            break;
        case SEEK_END:
            source->m_pendingSeek = source->m_size + args->offset;
            break;
        default:
            return -1;
        }
        return source->m_pendingSeek;
    }
    case ZIP_SOURCE_TELL:
        return source->m_pendingSeek;
    case ZIP_SOURCE_SUPPORTS:
        return ZIP_SOURCE_SUPPORTS_SEEKABLE;
    default:
        return -1;
    }
}
