#ifndef QMLPATHUTILS_H
#define QMLPATHUTILS_H

#include <QObject>
#include <QUrl>

class QQmlEngine;
class QJSEngine;

class QmlUrlUtils : public QObject {
    Q_OBJECT
public:
    static QObject* createInstance(QQmlEngine*, QJSEngine*) {
        return new QmlUrlUtils;
    }

public slots:
    QUrl resolved(QUrl const& url, QUrl const& relative) {
        return url.resolved(relative);
    }

    QString urlToLocalFile(QUrl const& url) {
        return url.toLocalFile();
    }

    QUrl localFileToUrl(QString const& path) {
        return QUrl::fromLocalFile(path);
    }
    
    Q_INVOKABLE bool moveFile(const QString &sourcePath, const QString &destinationFolder) {
        QFile file(sourcePath);
        QString fileName = QFileInfo(file).fileName();
        QString destinationPath = QDir(destinationFolder).filePath(fileName);
        return file.rename(destinationPath);
    }
};

#endif // QMLPATHUTILS_H
