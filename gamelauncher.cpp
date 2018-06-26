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
    process->setProcessChannelMode(QProcess::MergedChannels);
    connect(process.get(), &QProcess::readyReadStandardOutput, this, &GameLauncher::handleStdOutAvailable);
    connect(process.get(), QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, &GameLauncher::handleFinished);
    process->start(GAME_PATH, args);
    m_crashed = false;
    m_log = QString();
    emit logChanged();
    emit stateChanged();
}

void GameLauncher::handleStdOutAvailable() {
    m_log += QString::fromUtf8(process->readAllStandardOutput());
    emit logChanged();
}

void GameLauncher::handleFinished(int exitCode, QProcess::ExitStatus exitStatus) {
    handleStdOutAvailable();
    if (exitCode != 0) {
        m_log += "Process exited with unexpected exit code: " + QString::number(exitCode) + "\n";
    } else {
        m_log += "Process exited normally\n";
    }
    m_crashed = (exitCode != 0);
    emit logChanged();
    emit stateChanged();
}
