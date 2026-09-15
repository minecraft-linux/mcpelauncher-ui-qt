#ifndef REMOTEZIPSOURCE_H
#define REMOTEZIPSOURCE_H

#include <string>
#include <atomic>
#include <mutex>
#include <thread>
#include <zip.h>

class RemoteZipSource {
    size_t m_size;
    size_t m_offset = 0;
    size_t m_pendingSeek = 0;
    std::thread m_worker;
    int m_readFd = -1;
    std::atomic<bool> m_cancelWorker{false};
    std::string m_url;
    std::string m_userAgent;
    std::string m_cookie;
    std::mutex m_errorMutex;
    std::string m_lastErrorMessage;
    zip_error_t m_lastError;
    bool m_hasError = false;

    static zip_int64_t callback(void *context, void *data, zip_uint64_t len, zip_source_cmd_t cmd);
    void stopWorker();
    void startWorker();
    void clearError();
    void setError(int zipError, int sysError, std::string const& message);

public:
    RemoteZipSource(size_t size, std::string url, std::string userAgent, std::string cookie);
    ~RemoteZipSource();

    zip_source_t* create();
};

#endif
