#ifndef GOOGLEAPKDOWNLOADTASK_H
#define GOOGLEAPKDOWNLOADTASK_H

#include <QObject>
#include <QTemporaryFile>
#include <QMutex>
#include <zlib.h>
#include <playapi/api.h>
#include <utility>

class GooglePlayApi;

struct DownloadProgress {
    std::mutex mtx;
    size_t downloadsize;
    size_t downloads;
    std::vector<size_t> progress;
};

class GoogleApkDownloadTask : public QObject {
    Q_OBJECT
    Q_PROPERTY(GooglePlayApi* playApi WRITE setPlayApi)
    Q_PROPERTY(QString packageName WRITE setPackageName READ packageName)
    Q_PROPERTY(qint32 versionCode WRITE setVersionCode READ versionCode)
    Q_PROPERTY(bool active READ active NOTIFY activeChanged)
    Q_PROPERTY(QStringList filePaths READ filePaths)

private:
    GooglePlayApi* m_playApi = nullptr;
    QString m_packageName;
    qint32 m_versionCode;
    QMutex fileMutex;
    std::vector<std::shared_ptr<QTemporaryFile>> files;
    std::atomic_bool m_active;

    void startDownload(playapi::proto::finsky::download::AndroidAppDeliveryData const &dd, bool skipMainApk = false);

    static bool curlDoZlibInflate(z_stream& zs, int file, char* data, size_t len, int flags);

    template<class T, class U> void downloadFile(T const&dd, U cookie, std::function<void()> success, std::function<void()> error, std::shared_ptr<DownloadProgress> progress, size_t id);
public:
    explicit GoogleApkDownloadTask(QObject *parent = nullptr);

    void setPlayApi(GooglePlayApi* value);

    bool active() const { return m_active; }

    QString packageName() const { return m_packageName; }
    void setPackageName(QString packageName) { m_packageName = packageName; }

    qint32 versionCode() const { return m_versionCode; }
    void setVersionCode(qint32 versionCode) { m_versionCode = versionCode; }

    QStringList filePaths();

signals:
    void progress(qreal progress);

    void finished();

    void error(QString const& err);

    void activeChanged();

    void queueDownload(playapi::proto::finsky::download::AndroidAppDeliveryData dd, bool skipMainApk);

public slots:
    void start(bool skipMainApk = false);
};

#endif // GOOGLEAPKDOWNLOADTASK_H
