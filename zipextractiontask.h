#ifndef ZIPEXTRACTIONTASK_H
#define ZIPEXTRACTIONTASK_H

#include <QThread>
#include <QMutex>
#include <QTemporaryDir>
#include "versionmanager.h"

class ZipExtractionTask : public QThread {
    Q_OBJECT
    Q_PROPERTY(QStringList sources READ sources WRITE setSources)
    Q_PROPERTY(bool active READ active NOTIFY activeChanged)
    Q_PROPERTY(QString tempTemplate READ tempTemplate WRITE setTempTemplate NOTIFY activeChanged)
    Q_PROPERTY(QString targetDir READ targetDir WRITE setTargetDir NOTIFY activeChanged)

    QMutex mutex;
    QStringList m_sources;
    QString m_tempTemplate;
    QString m_targetDir;

    void run() override;

    void emitActiveChanged() {
        emit activeChanged();
    }

public:
    explicit ZipExtractionTask(QObject *parent = nullptr);

    bool active() const { return isRunning(); }

    QStringList sources() {
        QMutexLocker locker(&mutex);
        return m_sources;
    }

    void setSources(QStringList const& value) {
        QMutexLocker locker(&mutex);
        m_sources = value;
    }

    QString tempTemplate() const {
        return m_tempTemplate;
    }
    void setTempTemplate(QString const& value) {
        m_tempTemplate = value;
    }

    QString targetDir() const {
        return m_targetDir;
    }
    void setTargetDir(QString const& value) {
        m_targetDir = value;
    }

public slots:
    bool setSourceUrls(QList<QUrl> const& urls);

signals:
    void progress(qreal progress);

    void finished();

    void error(QString const& err);

    void activeChanged();

};

#endif // ZIPEXTRACTIONTASK_H
