import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.2
import QtQuick.Controls 2.1
import io.mrarm.mcpelauncher 1.0

Window {
    id: window
    visible: true
    width: 640
    height: 480
    title: qsTr("Linux Minecraft Launcher")
    flags: Qt.Dialog

    StackView {
        id: stackView
        anchors.fill: parent
    }


    GoogleLoginHelper {
        id: googleLoginHelperInstance
    }

    VersionManager {
        id: versionManagerInstance
    }

    ProfileManager {
        id: profileManagerInstance
    }

    Component {
        id: panelLogin

        LauncherLogin {
            googleLoginHelper: googleLoginHelperInstance
            versionManager: versionManagerInstance
            onFinished: stackView.replace(panelMain)
        }
    }

    Component {
        id: panelMain

        LauncherMain {
            googleLoginHelper: googleLoginHelperInstance
            versionManager: versionManagerInstance
            profileManager: profileManagerInstance
        }
    }

    Component {
        id: panelError

        LauncherUnsupported {
            googleLoginHelper: googleLoginHelperInstance
            versionManager: versionManagerInstance
            onFinished: {
                if (needsToLogIn()) {
                    stackView.push(panelLogin);
                } else {
                    stackView.push(panelMain);
                }
            }
        }
    }

    Component {
        id: panelChangelog

        LauncherChangeLog {
            googleLoginHelper: googleLoginHelperInstance
            versionManager: versionManagerInstance
            onFinished: {
                launcherSettings.lastVersion = LAUNCHER_VERSION_CODE
                next()
            }
        }
    }

    LauncherSettings {
        id: launcherSettings
    }

    function needsToLogIn() {
        return googleLoginHelperInstance.account == null && versionManagerInstance.versions.size === 0
    }

    Component.onCompleted: {
        if(LAUNCHER_CHANGE_LOG.length !== 0 && launcherSettings.lastVersion < LAUNCHER_VERSION_CODE) {
            stackView.push(panelChangelog);
        } else {
            next();
        }
    }

    function next() {
        if (!googleLoginHelperInstance.isSupported()) {
            stackView.push(panelError);
        } else {
            defaultnext();
        }
    }

    function defaultnext() {
        if (needsToLogIn()) {
            stackView.push(panelLogin);
        } else {
            stackView.push(panelMain);
        }
    }

}
