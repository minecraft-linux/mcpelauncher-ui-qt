#ifndef GAMELAUNCHER_H
#define GAMELAUNCHER_H

#include <QObject>
#include <QProcess>>

class GameLauncher : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString gameDir READ gameDir WRITE setGameDir)
private:
    QScopedPointer<QProcess> process;
    QString m_gameDir;

public:
    explicit GameLauncher(QObject *parent = nullptr);

    QString const& gameDir() { return m_gameDir; }

    void setGameDir(QString const& value) { m_gameDir = value; }

public slots:
    void start();
};

#endif // GAMELAUNCHER_H
