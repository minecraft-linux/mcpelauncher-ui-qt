#include "launcherapp.h"
#include <QIcon>
#include <QFileOpenEvent>
#include <QDebug>
#include "profilemanager.h"
#include "versionmanager.h"
#include "gamelauncher.h"
#include "googleversionchannel.h"

LauncherApp::LauncherApp(int &argc, char **argv) : QApplication(argc, argv) {
    auto appdir = getenv("APPDIR");
    if(appdir != nullptr)
        setWindowIcon(QIcon(QString::fromUtf8(appdir) + "/mcpelauncher-ui-qt.png"));
}

bool LauncherApp::event(QEvent *event) {
    if (event->type() == QEvent::Close) {
        AppCloseEvent qmlEvent;
        emit closing(&qmlEvent);
        if (!qmlEvent.isAccepted()) {
            event->setAccepted(false);
            return true;
        }
    } else if (event->type() == QEvent::FileOpen) {
        QFileOpenEvent *openEvent = static_cast<QFileOpenEvent *>(event);
        qDebug() << "Open file" << openEvent->file();
        launchProfileFile("", openEvent->file(), false);
    }
    return QApplication::event(event);
}

int LauncherApp::launchProfileFile(QString profileName, QString filePath, bool startEventLoop) {
    VersionManager vmanager;
    ProfileManager manager;
    ProfileInfo * profile = nullptr;
    if(profileName.length() > 0) {
        for(auto&& pro : manager.profiles()) {
            if(((ProfileInfo *)pro)->name == profileName) {
                profile = (ProfileInfo *)pro;
            }
        }
        if(profile == nullptr) {
            printf("Profile not found: %s\n", profileName.toStdString().data());
            return 1;
        }
    } else {
        profile = manager.activeProfile();
    }

    GameLauncher launcher;
    launcher.logAttached();
    QObject::connect(&launcher, &GameLauncher::logAppended, [](QString str) {
        printf("%s", str.toStdString().data());
    });
    QObject::connect(&launcher, &GameLauncher::stateChanged, [&]() {
        if(!launcher.running() && startEventLoop) {
            this->exit(launcher.crashed() ? 1 : 0);
        }
    });
    QObject::connect(&launcher, &GameLauncher::launchFailed, [&]() {
        if(startEventLoop) {
            this->exit(1);
        }
    });
    QObject::connect(&launcher, &GameLauncher::fileStarted, [&](bool success) {
        if(success) {
            if(startEventLoop) {
                this->exit(success ? 0 : 1);
            }
        } else {
            launcher.start(false, profile->arch, true, filePath);
        }
    });
    launcher.setProfile(profile);
    if(profile->versionType == ProfileInfo::LATEST_GOOGLE_PLAY) {
        GoogleVersionChannel playChannel;
        launcher.setGameDir(vmanager.getDirectoryFor(vmanager.versionList()->get(playChannel.latestVersionCode())));
    } else if(profile->versionType == ProfileInfo::LOCKED_NAME) {
        launcher.setGameDir(vmanager.getDirectoryFor(profile->versionDirName));
    } else if(profile->versionType == ProfileInfo::LOCKED_CODE && profile->versionCode) {
        launcher.setGameDir(vmanager.getDirectoryFor(vmanager.versionList()->get(profile->versionCode)));
    }
    
    if(filePath.length() > 0) {
        launcher.startFile(filePath);
    } else {
        launcher.start(false, profile->arch, true);
    }
    return launcher.running() ? (startEventLoop ? this->exec() : 0) : 1;
}


#ifndef __APPLE__
void LauncherApp::setVisibleInDock(bool) {
    // stub
}
#endif
