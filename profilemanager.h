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
    Q_PROPERTY(ProfileInfo* defaultProfile READ defaultProfile CONSTANT)
    Q_PROPERTY(ProfileInfo* activeProfile READ activeProfile WRITE setActiveProfile NOTIFY activeProfileChanged)
private:
    QString m_baseDir;
    QScopedPointer<QSettings> m_settings;
    QList<ProfileInfo*> m_profiles;
    ProfileInfo* m_defaultProfile;
    ProfileInfo* m_activeProfile;

    void loadProfiles();

public:
    explicit ProfileManager(QObject *parent = nullptr);

    QSettings& settings() { return *m_settings; }

    ProfileInfo* defaultProfile() const { return m_defaultProfile; }

    QList<QObject*> const& profiles() const { return (QList<QObject*>&) m_profiles; }


    ProfileInfo* activeProfile() const { return m_activeProfile; }

    void setActiveProfile(ProfileInfo* profile);

public slots:
    ProfileInfo* createProfile(QString name);

    void deleteProfile(ProfileInfo* profile);

    bool validateName(QString const& name);

signals:
    void profilesChanged();

    void activeProfileChanged();

};

#endif // PROFILEMANAGER_H
