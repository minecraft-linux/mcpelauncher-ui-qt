#include "gamelauncher.h"
#include "profilemanager.h"
#include "EnvPathUtil.h"

GameLauncher::GameLauncher(QObject *parent) : QObject(parent) {
}

std::string GameLauncher::findLauncher() {
    std::string path;
#ifdef GAME_LAUNCHER_PATH
    if (EnvPathUtil::findInPath("mcpelauncher-client", path, GAME_LAUNCHER_PATH, EnvPathUtil::getAppDir().c_str()))
        return path;
#endif
    if (EnvPathUtil::findInPath("mcpelauncher-client", path))
        return path;
    return std::string();
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
    connect(process.data(), &QProcess::readyReadStandardOutput, this, &GameLauncher::handleStdOutAvailable);
    connect(process.data(), QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, &GameLauncher::handleFinished);
    connect(process.data(), &QProcess::errorOccurred, this, &GameLauncher::handleError);
    process->start(QString::fromStdString(findLauncher()), args);
    m_crashed = false;
    emit logCleared();
    emit stateChanged();
}

void GameLauncher::handleStdOutAvailable() {
    emit logAppended(QString::fromUtf8(process->readAllStandardOutput()));
}

void GameLauncher::handleFinished(int exitCode, QProcess::ExitStatus exitStatus) {
    handleStdOutAvailable();
    QString msg;
    if (exitCode != 0) {
        msg = "Process exited with unexpected exit code: " + QString::number(exitCode) + "\n";
    } else {
        msg = "Process exited normally\n";
    }
    m_crashed = (exitCode != 0);
    process.reset();
    emit logAppended(msg);
    emit stateChanged();
}

void GameLauncher::handleError(QProcess::ProcessError error) {
    if (error == QProcess::FailedToStart)
        launchFailed();
}

void GameLauncher::kill() {
    if (process)
        process->kill();
}
