#ifndef VERSIONMANAGER_H
#define VERSIONMANAGER_H

#include <QObject>

class VersionManager : public QObject
{
    Q_OBJECT

private:
    QString baseDir;

public:
    VersionManager();

    // This is safe in a multi-thread env, because the baseDir can not be changed
    QString const& getBaseDir() const { return baseDir; }

    QString getTempTemplate();

    QString getDirectoryFor(std::string const& versionName);

public slots:
    QStringList listVersions() const;

    bool hasVersion(QString version) const;

};

#endif // VERSIONMANAGER_H
