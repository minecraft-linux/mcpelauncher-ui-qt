#ifndef PROFILEMANAGER_H
#define PROFILEMANAGER_H

#include <QObject>
#include <QList>
#include <QSettings>

class ProfileManager;

class ProfileInfo : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString name MEMBER name WRITE setName NOTIFY changed)
    Q_PROPERTY(bool nameLocked MEMBER nameLocked CONSTANT)
    Q_PROPERTY(VersionType versionType MEMBER versionType NOTIFY changed)
    Q_PROPERTY(QString versionDirName MEMBER versionDirName NOTIFY changed)
    Q_PROPERTY(bool windowCustomSize MEMBER windowCustomSize NOTIFY changed)
    Q_PROPERTY(int windowWidth MEMBER windowWidth NOTIFY changed)
    Q_PROPERTY(int windowHeight MEMBER windowHeight NOTIFY changed)

    ProfileManager* manager;

public:
    enum VersionType {
        LATEST_GOOGLE_PLAY, LOCKED
    };
    Q_ENUM(VersionType)

    ProfileInfo(ProfileManager* pm = nullptr);

    bool nameLocked = false;
    QString name;
    VersionType versionType = VersionType::LATEST_GOOGLE_PLAY;
    QString versionDirName;

    bool windowCustomSize = false;
    int windowWidth = 720;
    int windowHeight = 480;

public slots:
    void setName(QString const& newName);

    void save();

signals:
    void changed();
};


class ProfileManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(QList<QObject*> profiles READ profiles NOTIFY profilesChanged)
    Q_PROPERTY(ProfileInfo* defaultProfile READ defaultProfile)
private:
    QString m_baseDir;
    QScopedPointer<QSettings> m_settings;
    QList<ProfileInfo*> m_profiles;
    ProfileInfo* m_defaultProfile;

    void loadProfiles();

public:
    explicit ProfileManager(QObject *parent = nullptr);

    QSettings& settings() { return *m_settings; }

    ProfileInfo* defaultProfile() const { return m_defaultProfile; }

    QList<QObject*> const& profiles() const { return (QList<QObject*>&) m_profiles; }

public slots:
    ProfileInfo* createProfile(QString name);

signals:
    void profilesChanged();

};

#endif // PROFILEMANAGER_H
