#ifndef GOOGLEAPKDOWNLOADTASK_H
#define GOOGLEAPKDOWNLOADTASK_H

#include <QObject>
#include <QTemporaryFile>
#include <QMutex>
#include <zlib.h>
#include <playapi/api.h>

class GooglePlayApi;

class GoogleApkDownloadTask : public QObject {
    Q_OBJECT
    Q_PROPERTY(GooglePlayApi* playApi WRITE setPlayApi)
    Q_PROPERTY(QString packageName WRITE setPackageName READ packageName)
    Q_PROPERTY(qint32 versionCode WRITE setVersionCode READ versionCode)
    Q_PROPERTY(bool active READ active NOTIFY activeChanged)
    Q_PROPERTY(QString filePath READ filePath)

private:
    GooglePlayApi* m_playApi = nullptr;
    QString m_packageName;
    qint32 m_versionCode;
    QMutex fileMutex;
    QScopedPointer<QTemporaryFile> file;
    std::atomic_bool m_active;

    void startDownload(playapi::proto::finsky::download::AndroidAppDeliveryData const &dd);

    static bool curlDoZlibInflate(z_stream& zs, int file, char* data, size_t len, int flags);

public:
    explicit GoogleApkDownloadTask(QObject *parent = nullptr);

    void setPlayApi(GooglePlayApi* value);

    bool active() const { return m_active; }

    QString packageName() const { return m_packageName; }
    void setPackageName(QString packageName) { m_packageName = packageName; }

    qint32 versionCode() const { return m_versionCode; }
    void setVersionCode(qint32 versionCode) { m_versionCode = versionCode; }

    QString filePath();

signals:
    void progress(qreal progress);

    void finished();

    void error(QString const& err);

    void activeChanged();

public slots:
    void start();
};

#endif // GOOGLEAPKDOWNLOADTASK_H
