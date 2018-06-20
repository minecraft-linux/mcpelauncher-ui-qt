#include "gamelauncher.h"

GameLauncher::GameLauncher(QObject *parent) : QObject(parent) {
}

void GameLauncher::start() {
    process.reset(new QProcess);
    process->start(GAME_PATH, QStringList());
}
