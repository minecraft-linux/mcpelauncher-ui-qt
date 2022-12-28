#ifndef VERSIONMANAGER_H
#define VERSIONMANAGER_H

#include <QObject>
#include <QVector>
#include <QMap>
#include <QStringList>
#include "archivalversionlist.h"

class CodeInfo : public QObject {
    Q_OBJECT
    Q_PROPERTY(int code MEMBER code CONSTANT)
    Q_PROPERTY(QString arch MEMBER arch CONSTANT)
public:
    CodeInfo(int code, QString arch, QObject* parent = nullptr) : code(code), arch(arch), QObject(parent) {}
    int code;
    QString arch;
};

class VersionInfo : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString directory MEMBER directory CONSTANT)
    Q_PROPERTY(QString versionName MEMBER versionName CONSTANT)
    Q_PROPERTY(int versionCode READ versionCode CONSTANT)
    Q_PROPERTY(QStringList archs READ archs CONSTANT)
    Q_PROPERTY(QList<CodeInfo*> codes READ getCodes CONSTANT)
public:
    QString directory;
    QString versionName;
    QHash<QString, int> codes;

    VersionInfo(QObject* parent = nullptr) : QObject(parent) {}
    VersionInfo(VersionInfo const& v) : directory(v.directory), versionName(v.versionName), codes(v.codes) {}

    VersionInfo& operator=(VersionInfo const& v) {
        directory = v.directory;
        versionName = v.versionName;
        codes = v.codes;
        return *this;
    }

    QStringList archs() {
        QStringList archs;
        for (auto && arch : codes.keys()) {
            archs.append(arch);
        }
        return archs;
    }

    int versionCode() {
        for (auto && code : codes) {
            return code;
        }
        return -1;
    }

    QList<CodeInfo*> getCodes() {
        QList<CodeInfo*> l;
        QHash<QString, int>::const_iterator i = codes.constBegin();
        while (i != codes.constEnd()) {
            l.append(new CodeInfo(i.value(), i.key(), this));
            ++i;
        }
        return l;
    }
};

class VersionList : public QObject {
    Q_OBJECT
    Q_PROPERTY(int size READ size)
    Q_PROPERTY(VersionInfo* latestDownloadedVersion READ latestDownloadedVersion)

private:
    QMap<int, VersionInfo*>& m_versions;

public:
    VersionList(QMap<int, VersionInfo*>& versions) : m_versions(versions) {}

    int size() const { return m_versions.size(); }

    VersionInfo* latestDownloadedVersion() const;

public slots:
    QList<QObject*> getAll() const {
        QList<QObject*> ret;
        ret.reserve(m_versions.size());
        QMap<int, VersionInfo*>::const_iterator i = m_versions.constBegin();
        while (i != m_versions.constEnd()) {
            if (i.key() == i.value()->versionCode()) {
                ret.push_back(i.value());;
            }
            ++i;
        }
        return ret;
    }

    VersionInfo* get(int versionCode) const {
        auto it = m_versions.find(versionCode);
        if (it != m_versions.end())
            return it.value();
        return nullptr;
    }
    VersionInfo* getByDirectory(QString const& directory) const {
        for (VersionInfo* v : m_versions) {
            if (v->directory == directory)
                return v;
        }
        return nullptr;
    }

    bool contains(int versionCode) const { return m_versions.contains(versionCode); }

};

class VersionManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(VersionList* versions READ versionList NOTIFY versionListChanged)
    Q_PROPERTY(ArchivalVersionList* archivalVersions READ archivalVersionList NOTIFY archivalVersionListChanged)

private:
    QString baseDir;
    QMap<int, VersionInfo*> m_versions;
    VersionList m_versionList;
    ArchivalVersionList m_archival;

    void loadVersions();
    void saveVersions();

public:
    VersionManager();

    // This is safe in a multi-thread env, because the baseDir can not be changed
    QString const& getBaseDir() const { return baseDir; }

    QString getTempTemplate();

    QString getDirectoryFor(std::string const& versionName);

    void addVersion(QString directory, QString versionName, int versionCode);

    int latestDownloadedVersion() const;

    VersionList* versionList() { return &m_versionList; }

    ArchivalVersionList* archivalVersionList() { return &m_archival; }

public slots:
    QString getDirectoryFor(QString const& versionName);

    QString getDirectoryFor(VersionInfo* version);

    void removeVersion(VersionInfo* version);

    void removeVersion(VersionInfo* version, QStringList abis);

    void downloadLists(QStringList abis, QString baseUrl) {
        m_archival.downloadLists(abis, baseUrl);
    }

    bool checkSupport(QString const& versionName);

    bool checkSupport(VersionInfo *version);
    
signals:
    void versionListChanged();

    void archivalVersionListChanged();

};

#endif // VERSIONMANAGER_H
