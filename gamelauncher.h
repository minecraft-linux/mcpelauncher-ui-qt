#ifndef GAMELAUNCHER_H
#define GAMELAUNCHER_H

#include <QObject>
#include <QProcess>

class ProfileInfo;

class GameLauncher : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString gameDir READ gameDir WRITE setGameDir)
    Q_PROPERTY(ProfileInfo* profile READ profile WRITE setProfile)
    Q_PROPERTY(bool crashed READ crashed NOTIFY stateChanged)
    Q_PROPERTY(bool running READ running NOTIFY stateChanged)

private:
    QScopedPointer<QProcess> process;
    QScopedPointer<QProcess> fileprocess;
    QString m_gameDir;
    ProfileInfo* m_profile;
    bool m_crashed = false;
    bool m_gamelogopen = false;
    bool m_disableGameLog = false;

    void handleStdOutAvailable();

    void handleFinished(int exitCode, QProcess::ExitStatus exitStatus);

    void handleError(QProcess::ProcessError error);

public:
    explicit GameLauncher(QObject *parent = nullptr);

    static std::string findLauncher(std::string name);

    QString const& gameDir() { return m_gameDir; }

    void setGameDir(QString const& value) { m_gameDir = value; }

    ProfileInfo* profile() { return m_profile; }

    void setProfile(ProfileInfo* value) { m_profile = value; }

    bool running() const { return !process.isNull() && !m_crashed; }

    bool crashed() const { return m_crashed; }

public slots:
    void start(bool disableGameLog, QString arch = "", bool hasVerifiedLicense = true, QString filepath = "");
    void startFile(QString file);

    void kill();

    void logAttached();

    void logDetached();

signals:
    void logCleared();

    void logAppended(QString const& text);

    void stateChanged();

    void launchFailed();

    void corruptedInstall();

    void fileStarted(bool success);
};

#endif // GAMELAUNCHER_H
