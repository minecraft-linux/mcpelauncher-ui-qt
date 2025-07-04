#ifndef DownloadTask_H
#define DownloadTask_H

#include <QObject>
#include <QTemporaryFile>
#include <QMutex>
#include <zlib.h>
#include <utility>
#include <playapi/api.h>

// struct DownloadProgress {
//     std::mutex mtx;
//     size_t downloadsize;
//     size_t downloads;
//     std::vector<size_t> progress;
// };
#include <googleapkdownloadtask.h>

struct DownloadData {
    std::string url;
    std::string gzippedUrl;

    std::string cookie;
    std::shared_ptr<DownloadProgress> progress;
    std::string componentName;
    size_t id;
    bool isGzipped = false;
    size_t downloadSize = 0;
    size_t gzippedDownloadSize = 0;

    DownloadData(std::string url, std::string cookie, std::shared_ptr<DownloadProgress> progress, std::string componentName, size_t id)
        : url(std::move(url)), cookie(std::move(cookie)), progress(std::move(progress)), componentName(std::move(componentName)), id(id) {}
};

class DownloadTask : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool active READ active NOTIFY activeChanged)
    Q_PROPERTY(QStringList filePaths READ filePaths)
    Q_PROPERTY(bool keepDownload READ keepApks WRITE setKeepApks)
    Q_PROPERTY(bool dryrun MEMBER m_dryrun)

private:
    QMutex fileMutex;
    std::vector<std::shared_ptr<QTemporaryFile>> files;
    std::atomic_bool m_active;
    bool m_keepDownload = false;
    bool m_dryrun = false;

    void startDownload(std::vector<DownloadData> const& dd);

    static bool curlDoZlibInflate(z_stream& zs, int file, char* data, size_t len, int flags);

    void downloadFile(DownloadData const&dd, std::function<void()> success, std::function<void()> error, std::shared_ptr<DownloadProgress> progress, std::string componentName, size_t id);
public:
    explicit DownloadTask(QObject *parent = nullptr);

    bool active() const { return m_active; }

    bool keepApks() const { return m_keepDownload; }
    void setKeepApks(bool keepApks) { m_keepDownload = keepApks; }

    QStringList filePaths();

signals:
    void progress(qreal progress);

    void finished();

    void error(QString const& err);

    void activeChanged();

    void queueDownload(std::vector<DownloadData> dd);

    void downloadInfo(QString const& url);

public slots:
    void start(bool skipMainApk = false);
};

#endif // DownloadTask_H
