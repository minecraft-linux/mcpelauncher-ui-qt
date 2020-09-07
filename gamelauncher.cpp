#include "gamelauncher.h"
#include "profilemanager.h"
#include "EnvPathUtil.h"
#include <QFile>
#include <QDir>
#include "supportedandroidabis.h"
#include <sstream>

GameLauncher::GameLauncher(QObject *parent) : QObject(parent) {
}

std::string GameLauncher::findLauncher(bool is32) {
    std::string path;
    std::string name = "mcpelauncher-client";
#if (defined(__x86_64__) || defined(__aarch64__)) && !defined(DISABLE_64BIT)
    if(is32) {
        name += "32";
    }
#endif

#ifdef GAME_LAUNCHER_PATH
    if (EnvPathUtil::findInPath(name, path, GAME_LAUNCHER_PATH, EnvPathUtil::getAppDir().c_str()))
        return path;
#endif
    if (EnvPathUtil::findInPath(name, path))
        return path;
    return std::string();
}

#if defined(__x86_64__) && !defined(PREFER_32BIT) && !defined(DISABLE_64BIT)
#define __ANRABI64BIT__ "x86_64"
#elif defined(__aarch64__) && !defined(PREFER_32BIT) && !defined(DISABLE_64BIT)
#define __ANRABI64BIT__ "arm64-v8a"
#endif
#if defined(__i386__) || defined(__x86_64__) && !defined(DISABLE_32BIT)
#define __ANRABI32BIT__ "x86"
#elif defined(__arm__) || defined(__aarch64__) && !defined(DISABLE_32BIT)
#define __ANRABI32BIT__ "armeabi-v7a"
#endif

void GameLauncher::start(bool disableGameLog) {
    if (running()) {
        return;
    }
    m_disableGameLog = disableGameLog;
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
    process->setProcessChannelMode(QProcess::MergedChannels);
    if (m_disableGameLog) {
        #ifdef _WIN32
            process->setStandardOutputFile("nul");
        #else
            process->setStandardOutputFile("/dev/null");
        #endif
    }
    
    if (m_gamelogopen)
        logAttached();
    connect(process.data(), QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, &GameLauncher::handleFinished);
    connect(process.data(), &QProcess::errorOccurred, this, &GameLauncher::handleError);
    m_crashed = false;
    
    auto supportedabis = SupportedAndroidAbis::getAbis();
#ifdef __ANRABI32BIT__
    if (QDir(m_gameDir + "/libs").exists()) {
        QDir().mkpath(m_gameDir + "/lib/");
        QDir(m_gameDir + "/libs").rename(m_gameDir + "/libs", m_gameDir + "/lib/" __ANRABI32BIT__);
    }
#endif
    bool use32bitsuffix = false;
    std::string launcherpath = "mcpelauncher-client";
#ifdef __ANRABI64BIT__
    bool support64 = supportedabis.find(__ANRABI64BIT__) != supportedabis.end();
    bool lib64 = QFile(m_gameDir + "/lib/" __ANRABI64BIT__ "/libminecraftpe.so").exists();
    bool launcher64 = !(launcherpath = findLauncher(use32bitsuffix)).empty();
    if (!support64 || !lib64 || !launcher64) {
        use32bitsuffix = true;
#endif
#ifdef __ANRABI32BIT__
        bool support32 = supportedabis.find(__ANRABI32BIT__) != supportedabis.end();
        bool lib32 = QFile(m_gameDir + "/lib/" __ANRABI32BIT__ "/libminecraftpe.so").exists();
        bool launcher32 = !(launcherpath = findLauncher(use32bitsuffix)).empty();
        if (!support32 || !lib32 || !launcher32) {
#endif
            std::stringstream errormsg;
#ifdef __ANRABI64BIT__
            errormsg << "Minecraft (" << __ANRABI64BIT__  << "):\n";
            errormsg << "  Supported on your Device? " << (support64 ? "Yes" : "No") << "\n";
            errormsg << "  Game Installed? " << (lib64 ? "Yes" : "No") << "\n";
            errormsg << "  Launcher Installed? " << (launcher64 ? "Yes" : "No") << "\n";
#endif
#ifdef __ANRABI32BIT__
            errormsg << "Minecraft (" << __ANRABI32BIT__  << "):\n";
            errormsg << "  Supported on your Device? " << (support32 ? "Yes" : "No") << "\n";
            errormsg << "  Game Installed? " << (lib32 ? "Yes" : "No") << "\n";
            errormsg << "  Launcher Installed? " << (launcher32 ? "Yes" : "No") << "\n";
#endif
            for (auto&& abi : SupportedAndroidAbis::getAbis()) {
#ifdef __ANRABI64BIT__
                if (abi.first == __ANRABI64BIT__) {
                    continue;
                }
#endif
#ifdef __ANRABI32BIT__
                if (abi.first == __ANRABI32BIT__) {
                    continue;
                }
#endif
                errormsg << "Minecraft (" << abi.first << "):\n";
                errormsg << "  Supported on your Device? N/A\n";
                errormsg << "  Game Installed? " << (QFile(m_gameDir + "/lib/" + QString::fromStdString(abi.first) + "/libminecraftpe.so").exists() ? "Yes" : "No") << "\n";
                errormsg << "  Launcher Installed? " << "No" << "\n";
            }
            process.reset();
            m_crashed = true;
            emit logCleared();
            emit logAppended(QString::fromStdString(errormsg.str()));
            emit stateChanged();
            return;
#ifdef __ANRABI32BIT__
        }
#endif
#ifdef __ANRABI64BIT__
    }
#endif

    process->start(QString::fromStdString(launcherpath), args);
    emit logCleared();
    emit stateChanged();
}

void GameLauncher::handleStdOutAvailable() {
    emit logAppended(QString::fromUtf8(process->readAllStandardOutput()));
}

void GameLauncher::handleFinished(int exitCode, QProcess::ExitStatus exitStatus) {
    if(!m_disableGameLog) {
        handleStdOutAvailable();
    }
    QString msg;
    switch (exitCode)
    {
    case 51: // Failed to load Minecraft lib
        msg = "Unsupported or corrupted Minecraft install detected, please delete the Version in settings and redownload\n";
        emit corruptedInstall();
        break;
    case 127: // Failed to load launcher dependencies (GNU/Linux)
        msg = "Missing launcher dependencies, please install all missing libraries in their right version";
        emit launchFailed();
        break;
    default:
        if (exitCode != 0) {
            msg = "Process exited with unexpected exit code: " + QString::number(exitCode) + "\n";
        } else {
            msg = "Process exited normally\n";
        }
        if (m_crashed = (exitCode != 0)) {
            logAttached();
        }
        break;
    }
    process.reset();
    emit logAppended("\n" + msg);
    emit stateChanged();
}

void GameLauncher::handleError(QProcess::ProcessError error) {
    if (error == QProcess::FailedToStart) {
        m_crashed = true;
        logAttached();
        emit logAppended("Your system is unable to execute the launcher");
        emit stateChanged();
        launchFailed();
    }
}

void GameLauncher::kill() {
    if (running()) {
        process->kill();
        process->waitForFinished();
        process.reset();
        emit stateChanged();
    }
}

void GameLauncher::logAttached() {
    if(!m_disableGameLog) {
        m_gamelogopen = true;
        if (process) {
            connect(process.data(), &QProcess::readyReadStandardOutput, this, &GameLauncher::handleStdOutAvailable);
        }
    }
}

void GameLauncher::logDetached() {
    if(!m_disableGameLog) {
        m_gamelogopen = false;
        if (process) {
            disconnect(process.data(), &QProcess::readyReadStandardOutput, this, &GameLauncher::handleStdOutAvailable);
        }
    }
}