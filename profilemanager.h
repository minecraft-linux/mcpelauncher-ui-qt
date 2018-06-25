#ifndef PROFILEMANAGER_H
#define PROFILEMANAGER_H

#include <QObject>
#include <QList>

class ProfileInfo : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString name MEMBER name NOTIFY changed)
    Q_PROPERTY(VersionType versionType MEMBER versionType NOTIFY changed)
    Q_PROPERTY(QString versionDirName MEMBER versionDirName NOTIFY changed)
    Q_PROPERTY(bool windowCustomSize MEMBER windowCustomSize NOTIFY changed)
    Q_PROPERTY(int windowWidth MEMBER windowWidth NOTIFY changed)
    Q_PROPERTY(int windowHeight MEMBER windowHeight NOTIFY changed)

public:
    enum VersionType {
        LATEST_GOOGLE_PLAY, LOCKED
    };
    Q_ENUM(VersionType)

    explicit ProfileInfo(QObject *parent = nullptr) : QObject(parent) {}

    QString name;
    VersionType versionType = VersionType::LATEST_GOOGLE_PLAY;
    QString versionDirName;

    bool windowCustomSize = false;
    int windowWidth = 720;
    int windowHeight = 480;

signals:
    void changed();
};


class ProfileManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(QList<QObject*> profiles READ profiles NOTIFY profilesChanged)
    Q_PROPERTY(ProfileInfo* defaultProfile READ defaultProfile)
private:
    QList<ProfileInfo*> m_profiles;
    ProfileInfo* m_defaultProfile;

public:
    explicit ProfileManager(QObject *parent = nullptr);

    ProfileInfo* defaultProfile() const { return m_defaultProfile; }

    QList<QObject*> const& profiles() const { return (QList<QObject*>&) m_profiles; }

signals:
    void profilesChanged();

};

#endif // PROFILEMANAGER_H
