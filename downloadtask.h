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

#include <QObject>
#include <QString>
#include <memory>

class DownloadDataWrapper : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString url READ url WRITE setUrl NOTIFY urlChanged)
    Q_PROPERTY(QString gzippedUrl READ gzippedUrl WRITE setGzippedUrl NOTIFY gzippedUrlChanged)
    Q_PROPERTY(QString cookie READ cookie WRITE setCookie NOTIFY cookieChanged)
    Q_PROPERTY(QString componentName READ componentName WRITE setComponentName NOTIFY componentNameChanged)
    Q_PROPERTY(bool isGzipped READ isGzipped WRITE setIsGzipped NOTIFY isGzippedChanged)
    Q_PROPERTY(size_t id READ id WRITE setId NOTIFY idChanged)
    Q_PROPERTY(size_t downloadSize READ downloadSize WRITE setDownloadSize NOTIFY downloadSizeChanged)
    Q_PROPERTY(size_t gzippedDownloadSize READ gzippedDownloadSize WRITE setGzippedDownloadSize NOTIFY gzippedDownloadSizeChanged)

public:
    explicit DownloadDataWrapper(QObject *parent = nullptr);

    // Getters
    QString url() const;
    QString gzippedUrl() const;
    QString cookie() const;
    QString componentName() const;
    bool isGzipped() const;
    size_t id() const;
    size_t downloadSize() const;
    size_t gzippedDownloadSize() const;

    // Setters
    void setUrl(const QString &value);
    void setGzippedUrl(const QString &value);
    void setCookie(const QString &value);
    void setComponentName(const QString &value);
    void setIsGzipped(bool value);
    void setId(size_t value);
    void setDownloadSize(size_t value);
    void setGzippedDownloadSize(size_t value);

    DownloadData toNative() {
        return DownloadData(
            this->url().toStdString(),
            this->cookie().toStdString(),
            nullptr, // You'd need logic for wrapping/unwrapping progress
            this->componentName().toStdString(),
            this->id()
        );
    }

signals:
    void urlChanged();
    void gzippedUrlChanged();
    void cookieChanged();
    void componentNameChanged();
    void isGzippedChanged();
    void idChanged();
    void downloadSizeChanged();
    void gzippedDownloadSizeChanged();

private:
    QString m_url;
    QString m_gzippedUrl;
    QString m_cookie;
    QString m_componentName;
    bool m_isGzipped = false;
    size_t m_id = 0;
    size_t m_downloadSize = 0;
    size_t m_gzippedDownloadSize = 0;
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

    Q_INVOKABLE void startDownload(const QList<DownloadDataWrapper*> &downloadList);

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
