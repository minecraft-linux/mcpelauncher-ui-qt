#ifndef APKEXTRACTIONTASK_H
#define APKEXTRACTIONTASK_H

#include <QThread>
#include <QMutex>
#include <QTemporaryDir>

class VersionManager;

class ApkExtractionTask : public QThread {
    Q_OBJECT
    Q_PROPERTY(VersionManager* versionManager READ versionManager WRITE setVersionManager)
    Q_PROPERTY(QStringList sources READ sources WRITE setSources)
    Q_PROPERTY(bool active READ active NOTIFY activeChanged)

    QMutex mutex;
    QStringList m_sources;
    VersionManager* m_versionManager;

    void run() override;

    void emitActiveChanged() {
        emit activeChanged();
    }

private slots:
    void onVersionInformationObtained(QString const& directory, QString const& versionName, int versionCode);


public:
    explicit ApkExtractionTask(QObject *parent = nullptr);

    bool active() const { return isRunning(); }

    QStringList sources() {
        QMutexLocker locker(&mutex);
        return m_sources;
    }

    void setSources(QStringList const& value) {
        QMutexLocker locker(&mutex);
        m_sources = value;
    }

    VersionManager* versionManager() {
        QMutexLocker locker(&mutex);
        return m_versionManager;
    }

    void setVersionManager(VersionManager* value) {
        QMutexLocker locker(&mutex);
        m_versionManager = value;
    }
public slots:
    bool setSourceUrls(QList<QUrl> const& urls);

signals:
    void progress(qreal progress);

    void versionInformationObtained(QString const& directory, QString const& versionName, int versionCode);

    void finished();

    void error(QString const& err);

    void activeChanged();

};

#endif // APKEXTRACTIONTASK_H
