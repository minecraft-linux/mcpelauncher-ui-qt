#include "gamelauncher.h"
#include "profilemanager.h"
#include "EnvPathUtil.h"
#include <QFile>
#include <QDir>
#include "supportedandroidabis.h"
#include "googleloginhelper.h"
#include "launchersettings.h"
#include <sstream>

GameLauncher::GameLauncher(QObject *parent) : QObject(parent), m_api(nullptr) {
}

std::string GameLauncher::findLauncher(std::string name) {
    std::string path;

#ifdef GAME_LAUNCHER_PATH
    if (EnvPathUtil::findInPath(name, path, GAME_LAUNCHER_PATH, EnvPathUtil::getAppDir().c_str()))
        return path;
#endif
    if (EnvPathUtil::findInPath(name, path))
        return path;
    return std::string();
}

void GameLauncher::start(bool disableGameLog, QString arch, bool hasVerifiedLicense) {
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
        if (m_profile->texturePatch != 0) {
            args.append("-tp");
            args.append(QString::number(m_profile->texturePatch == 1));
        }
    }
#ifdef LAUNCHER_ENABLE_GOOGLE_PLAY_LICENCE_CHECK
    if (!hasVerifiedLicense) {
        args.append("-fguv");
    }
#endif
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert("GPLAY_TOKEN_CACHE_PATH", QString::fromStdString(GoogleLoginHelper::getTokenCachePath()));
    if(m_api && m_api->getCheckin()) {
        env.insert("GPLAY_CHECKIN_ANDROID_ID", QString::fromStdString(std::to_string(m_api->getCheckin()->android_id)));
        env.insert("GPLAY_CHECKIN_DEVICE_DATA_VERSION_INFO", QString::fromStdString(m_api->getCheckin()->device_data_version_info));
    }
    if(LauncherSettings().allowLauncherExtensions()) {
        env.insert("MCPELAUNCHER_ALLOW_PROPRIETARY_EXTENSIONS", "1");
        // const char * modEnv = "MCPELAUNCHER_MOD_DIRS";
        // auto oldval = env.value(modEnv, "");
        // auto newval = QString::fromStdString();
        // env.insert(modEnv, oldval.isEmpty() ? newval : oldval + ":" + newval );
    }
    process->setProcessEnvironment(env);

    process->setProcessChannelMode(QProcess::MergedChannels);
    if (m_disableGameLog) {
        #ifdef _WIN32
            process->setStandardOutputFile("nul");
        #else
            process->setStandardOutputFile("/dev/null");
        #endif
    }
    emit logCleared();
    
    if (m_gamelogopen)
        logAttached();
    connect(process.data(), QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, &GameLauncher::handleFinished);
    connect(process.data(), &QProcess::errorOccurred, this, &GameLauncher::handleError);
    m_crashed = false;
    std::stringstream errormsg;
    auto abis = SupportedAndroidAbis::getAbis();
    std::string launcherpath;
    auto _arch = arch.toStdString();
    for (auto&& abi : abis) {
        if((_arch.empty() || _arch == abi.first) && QFile(m_gameDir + "/lib/" + QString::fromStdString(abi.first) + "/libminecraftpe.so").exists()) {
            if(!(launcherpath = findLauncher(abi.second.launchername)).empty()) {
                process->start(QString::fromStdString(launcherpath), args);
                emit stateChanged();
                return;
            } else {
                errormsg << tr("Could not find the gamelauncher for Minecraft (%1)\nPlease add the launcher '%2' to your 'PATH' (environmentvariable) and restart the launcher\n").arg(QString::fromStdString(abi.first)).arg(QString::fromStdString(abi.second.launchername)).toStdString();
            }
        }
    }
    process.reset();
    m_crashed = true;
    logAttached();
    emit stateChanged();
    emit logAppended(QString::fromStdString(errormsg.str()));
}

void GameLauncher::handleStdOutAvailable() {
    emit logAppended(QString::fromUtf8(process->readAllStandardOutput()));
}

void GameLauncher::handleFinished(int exitCode, QProcess::ExitStatus exitStatus) {
    if(!m_disableGameLog && process->bytesAvailable()) {
        handleStdOutAvailable();
    }
    QString msg;
    switch (exitCode)
    {
    case 51: // Failed to load Minecraft lib
        msg = tr("Incompatible Minecraft installation, please select a different or older Version\nThis Launcher is a free Open Source Software which usually fell behind official updates from Google Play\nIn some cases there are missing game files,\nmissing Symbols expected to be provided by this Launcher via updates\n or otherwise broke the Launcher");
        emit corruptedInstall();
        break;
    case 127: // Failed to load launcher dependencies (GNU/Linux)
        msg = tr("Missing launcher dependencies, please install all missing libraries in their right version");
        emit launchFailed();
        break;
    default:
        if (exitCode != 0) {
            msg = tr("Process exited with unexpected exit code: %1\n").arg(exitCode);
        } else {
            msg = tr("Process exited normally\n");
        }
        if (m_crashed = (exitCode != 0)) {
            logAttached();
        }
        break;
    }
    process.reset();
    if (!m_disableGameLog)
        emit logAppended("\n" + msg);
    emit stateChanged();
}

void GameLauncher::handleError(QProcess::ProcessError error) {
    if (error == QProcess::FailedToStart) {
        m_crashed = true;
        logAttached();
        emit logAppended(tr("Your system is unable to execute the launcher"));
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