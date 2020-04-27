#include "gamelauncher.h"
#include "profilemanager.h"
#include "EnvPathUtil.h"
#include <QFile>
#include <QDir>

GameLauncher::GameLauncher(QObject *parent) : QObject(parent) {
}

std::string GameLauncher::findLauncher(bool is32) {
    std::string path;
    std::string name = "mcpelauncher-client";
    if(is32) {
        name += "32";
    }

#ifdef GAME_LAUNCHER_PATH
    if (EnvPathUtil::findInPath(name, path, GAME_LAUNCHER_PATH, EnvPathUtil::getAppDir().c_str()))
        return path;
#endif
    if (EnvPathUtil::findInPath(name, path))
        return path;
    return std::string();
}

void GameLauncher::start(bool disableGameLog) {
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
        }
    }
    if (disableGameLog) {
        #ifdef _WIN32
            process->setStandardOutputFile("nul");
        #else
            process->setStandardOutputFile("/dev/null");
        #endif
    } else {
        process->setProcessChannelMode(QProcess::MergedChannels);
    }
    
    if (m_gamelogopen)
        logAttached();
    connect(process.data(), QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, &GameLauncher::handleFinished);
    connect(process.data(), &QProcess::errorOccurred, this, &GameLauncher::handleError);
    m_crashed = false;
    
    if (QFile(m_gameDir + "/libs/libminecraftpe.so").exists()) {
        QDir().rename(m_gameDir + "/libs", m_gameDir + "/lib/" +
#if defined(__i386__) || defined(__x86_64__)
            "x86"
#elif defined(__arm__) || defined(__aarch64__)
            "armeabi-v7a"
#endif
        );
    }

    process->start(QString::fromStdString(findLauncher(!QFile(m_gameDir + "/lib/"
#ifdef __x86_64__
"x86_64"
#elif defined(__aarch64__)
"arm64-v8a"
#elif defined(__i386__)
"x86"
#elif defined(__arm__)
"armeabi-v7a"
#endif
"/libminecraftpe.so").exists())), args);
    if(m_crashed)
        process.reset();
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
    if (m_crashed = (exitCode != 0)) {
        logAttached();
    }
    process.reset();
    emit logAppended(msg);
    emit stateChanged();
}

void GameLauncher::handleError(QProcess::ProcessError error) {
    if (error == QProcess::FailedToStart) {
        m_crashed = true;
        logAttached();
        launchFailed();
    }
}

void GameLauncher::kill() {
    if (process) {
        process->kill();
        process->waitForFinished();
    }
}

void GameLauncher::logAttached() {
    m_gamelogopen = true;
    if (process) {
        connect(process.data(), &QProcess::readyReadStandardOutput, this, &GameLauncher::handleStdOutAvailable);
    }
}

void GameLauncher::logDetached() {
    m_gamelogopen = false;
    if (process) {
        disconnect(process.data(), &QProcess::readyReadStandardOutput, this, &GameLauncher::handleStdOutAvailable);
    }
}