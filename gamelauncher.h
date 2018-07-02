#ifndef GAMELAUNCHER_H
#define GAMELAUNCHER_H

#include <QObject>
#include <QProcess>

class ProfileInfo;

class GameLauncher : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString gameDir READ gameDir WRITE setGameDir)
    Q_PROPERTY(ProfileInfo* profile READ profile WRITE setProfile)
    Q_PROPERTY(QString log READ log NOTIFY logChanged)
    Q_PROPERTY(bool crashed READ crashed NOTIFY stateChanged)

private:
    QScopedPointer<QProcess> process;
    QString m_gameDir;
    ProfileInfo* m_profile;
    QString m_log;
    bool m_crashed = false;

    void handleStdOutAvailable();

    void handleFinished(int exitCode, QProcess::ExitStatus exitStatus);

    static std::string findLauncher();

public:
    explicit GameLauncher(QObject *parent = nullptr);

    QString const& gameDir() { return m_gameDir; }

    void setGameDir(QString const& value) { m_gameDir = value; }

    ProfileInfo* profile() { return m_profile; }

    void setProfile(ProfileInfo* value) { m_profile = value; }

    QString const& log() const { return m_log; }

    bool crashed() const { return m_crashed; }

public slots:
    void start();

signals:
    void logChanged();

    void stateChanged();
};

#endif // GAMELAUNCHER_H
