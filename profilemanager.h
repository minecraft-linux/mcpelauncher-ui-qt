#ifndef PROFILEMANAGER_H
#define PROFILEMANAGER_H

#include <QObject>
#include <QList>
#include <QSettings>
#include <QQmlPropertyMap>

class ProfileManager;

class ProfileInfo : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString name MEMBER name WRITE setName NOTIFY changed)
    Q_PROPERTY(bool nameLocked MEMBER nameLocked CONSTANT)
    Q_PROPERTY(VersionType versionType MEMBER versionType NOTIFY changed)
    Q_PROPERTY(QString versionDirName MEMBER versionDirName NOTIFY changed)
    Q_PROPERTY(int versionCode MEMBER versionCode NOTIFY changed)
    Q_PROPERTY(bool dataDirCustom MEMBER dataDirCustom NOTIFY changed)
    Q_PROPERTY(QString dataDir MEMBER dataDir NOTIFY changed)
    Q_PROPERTY(bool windowCustomSize MEMBER windowCustomSize NOTIFY changed)
    Q_PROPERTY(int windowWidth MEMBER windowWidth NOTIFY changed)
    Q_PROPERTY(int windowHeight MEMBER windowHeight NOTIFY changed)
    Q_PROPERTY(QString arch MEMBER arch NOTIFY changed)
    Q_PROPERTY(int texturePatch MEMBER texturePatch WRITE setTexturePatch NOTIFY changed)
    Q_PROPERTY(QStringList mods MEMBER mods NOTIFY changed)
    Q_PROPERTY(QString commandline MEMBER commandline NOTIFY changed)
    Q_PROPERTY(QQmlPropertyMap* env MEMBER env NOTIFY changed)
#ifdef __APPLE__
    Q_PROPERTY(int graphicsAPI MEMBER graphicsAPI WRITE setGraphicsAPI NOTIFY changed)
#endif

    ProfileManager* manager;

public:
    enum VersionType {
        LATEST_GOOGLE_PLAY, LOCKED_NAME, LOCKED_CODE
    };
    Q_ENUM(VersionType)

    ProfileInfo(ProfileManager* pm = nullptr);

    bool nameLocked = false;
    QString name;
    VersionType versionType = VersionType::LATEST_GOOGLE_PLAY;
    QString versionDirName;
    int versionCode;

    bool dataDirCustom = false;
    QString dataDir;

    bool windowCustomSize = false;
    int windowWidth = 720;
    int windowHeight = 480;
#ifdef __APPLE__
    int graphicsAPI = 0;
#endif

    QString arch;

    int texturePatch = 0;

    QStringList mods;

    QString commandline;

    QQmlPropertyMap* env;

public slots:
    void setName(QString const& newName);

    void save();

    void setTexturePatch(int val) {
        texturePatch = val;
    }
#ifdef __APPLE__
    void setGraphicsAPI(int val) {
        graphicsAPI = val;
    }
#endif

    void clearEnv();

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
