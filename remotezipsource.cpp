#include "remotezipsource.h"

#include <playapi/util/http.h>

#include <QDebug>

#include <algorithm>
#include <cerrno>
#include <cstring>
#include <fcntl.h>
#include <stdexcept>
#include <sstream>
#include <unistd.h>

RemoteZipSource::RemoteZipSource(size_t size, std::string url, std::string userAgent, std::string cookie)
    : m_size(size), m_url(std::move(url)), m_userAgent(std::move(userAgent)), m_cookie(std::move(cookie)) {
}

RemoteZipSource::~RemoteZipSource() {
    stopWorker();
}

void RemoteZipSource::stopWorker() {
    if (m_readFd >= 0) {
        close(m_readFd);
        m_readFd = -1;
    }
    if (m_worker.joinable())
        m_worker.join();
}

void RemoteZipSource::startWorker() {
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
        playapi::http_request req(m_url);
        const auto rangeHeader = (std::stringstream() << "bytes=" << start << "-").str();
        req.set_method(playapi::http_method::GET);
        req.add_header("Accept-Encoding", "identity");
        req.add_header("Cookie", m_cookie);
        req.add_header("User-Agent", m_userAgent);
        req.add_header("Range", rangeHeader);
        req.set_follow_location(true);
        req.set_timeout(100L);
        req.set_custom_output_func([writeFd](char* data, size_t size) {
            return write(writeFd, data, size);
        });
        try {
            qDebug() << "RemoteZipSource: HTTP GET" << QString::fromStdString(rangeHeader);
            auto response = req.perform();
            qDebug() << "RemoteZipSource: HTTP completed: "
                     << "start=" << start << "status=" << response.get_status_code();
        } catch (...) {
            qDebug() << "RemoteZipSource: HTTP request threw"
                     << "start=" << start;
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
        return 0;
    case ZIP_SOURCE_CLOSE:
        source->stopWorker();
        return 0;
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
                close(source->m_readFd);
                source->m_readFd = -1;
                source->m_worker.join();
            }
            source->startWorker();
            worker_started = true;
        }
        ssize_t r = read(source->m_readFd, data, len);
        if(r == 0) {
            if(!worker_started) {
                qDebug() << "RemoteZipSource: main read returned 0, but worker not started, maybe corrupted?"
                         << "offset=" << source->m_offset
                         << "pending=" << source->m_pendingSeek
                         << "len=" << len;
            }
            if (source->m_worker.joinable()) {
                close(source->m_readFd);
                source->m_readFd = -1;
                source->m_worker.join();
            }
            return callback(context, data, len, ZIP_SOURCE_READ);
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
