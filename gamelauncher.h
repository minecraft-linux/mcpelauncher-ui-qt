#ifndef GAMELAUNCHER_H
#define GAMELAUNCHER_H

#include <QObject>
#include <QProcess>

class ProfileInfo;

class GameLauncher : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString gameDir READ gameDir WRITE setGameDir)
    Q_PROPERTY(ProfileInfo* profile READ profile WRITE setProfile)

private:
    QScopedPointer<QProcess> process;
    QString m_gameDir;
    ProfileInfo* m_profile;

public:
    explicit GameLauncher(QObject *parent = nullptr);

    QString const& gameDir() { return m_gameDir; }

    void setGameDir(QString const& value) { m_gameDir = value; }

    ProfileInfo* profile() { return m_profile; }

    void setProfile(ProfileInfo* value) { m_profile = value; }

public slots:
    void start();
};

#endif // GAMELAUNCHER_H
