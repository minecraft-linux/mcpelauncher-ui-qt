#ifndef GAMELAUNCHER_H
#define GAMELAUNCHER_H

#include <QObject>
#include <QProcess>>

class GameLauncher : public QObject
{
    Q_OBJECT
private:
    QScopedPointer<QProcess> process;

public:
    explicit GameLauncher(QObject *parent = nullptr);

public slots:
    void start();
};

#endif // GAMELAUNCHER_H
