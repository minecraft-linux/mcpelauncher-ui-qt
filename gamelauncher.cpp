#include "gamelauncher.h"

GameLauncher::GameLauncher(QObject *parent) : QObject(parent) {
}

void GameLauncher::start() {
    process.reset(new QProcess);
    QStringList args;
    if (m_gameDir.length() > 0) {
        args.append("-dg");
        args.append(m_gameDir);
    }
    process->start(GAME_PATH, args);
}
