#ifndef REMOTEZIPSOURCE_H
#define REMOTEZIPSOURCE_H

#include <string>
#include <thread>
#include <zip.h>

class RemoteZipSource {
    size_t m_size;
    size_t m_offset = 0;
    size_t m_pendingSeek = 0;
    std::thread m_worker;
    int m_readFd = -1;
    std::string m_url;
    std::string m_userAgent;
    std::string m_cookie;

    static zip_int64_t callback(void *context, void *data, zip_uint64_t len, zip_source_cmd_t cmd);
    void stopWorker();
    void startWorker();

public:
    RemoteZipSource(size_t size, std::string url, std::string userAgent, std::string cookie);
    ~RemoteZipSource();

    zip_source_t* create();
};

#endif
