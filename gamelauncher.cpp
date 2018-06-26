#include "gamelauncher.h"
#include "profilemanager.h"

GameLauncher::GameLauncher(QObject *parent) : QObject(parent) {
}

void GameLauncher::start() {
    process.reset(new QProcess);
    QStringList args;
    if (m_gameDir.length() > 0) {
        args.append("-dg");
        args.append(m_gameDir);
    }
    if (m_profile != nullptr) {
        if (m_profile->dataDirCustom) {
            args.append("-dd");
            args.append(m_profile->dataDir);
        }
        if (m_profile->windowCustomSize) {
            args.append("-ww");
            args.append(QString::number(m_profile->windowWidth));
            args.append("-wh");
            args.append(QString::number(m_profile->windowHeight));
            args.append("-s");
            args.append(QString::number(m_profile->pixelScale));
        }
    }
    process->start(GAME_PATH, args);
}
