#ifndef APKEXTRACTIONTASK_H
#define APKEXTRACTIONTASK_H

#include <QThread>
#include <QMutex>
#include <QTemporaryDir>

class ApkExtractionTask : public QThread
{
    Q_OBJECT
    Q_PROPERTY(QString source READ source WRITE setSource)
    Q_PROPERTY(QString destination READ destination WRITE setDestination)

    QMutex mutex;
    QString m_source;
    QString m_destination;
    QScopedPointer<QTemporaryDir> m_tempDir;

    void run() override;

public:
    explicit ApkExtractionTask(QObject *parent = nullptr);

    QString source() {
        QMutexLocker locker(&mutex);
        return m_source;
    }

    void setSource(QString const& value) {
        QMutexLocker locker(&mutex);
        m_source = value;
    }

    QString destination() {
        QMutexLocker locker(&mutex);
        return m_destination;
    }

    void setDestination(QString const& value) {
        QMutexLocker locker(&mutex);
        m_destination = value;
    }

public slots:
    void setDestinationTemporary() {
        QMutexLocker locker(&mutex);
        m_tempDir.reset(new QTemporaryDir());
        m_destination = m_tempDir->path();
    }

    bool setSourceUrl(QUrl const& url);

signals:
    void progress(qreal progress);

    void finished();

    void error();

};

#endif // APKEXTRACTIONTASK_H
