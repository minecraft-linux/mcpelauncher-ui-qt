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
    property bool hasUpdate: false
    property string updateDownloadUrl: ""

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
            playApiInstance: playApi
            hasUpdate: window.hasUpdate
            updateDownloadUrl: window.updateDownloadUrl
        }
    }

    Component {
        id: panelError

        LauncherUnsupported {
            googleLoginHelper: googleLoginHelperInstance
            onFinished: {
                if (needsToLogIn()) {
                    stackView.push(panelLogin);
                } else {
                    stackView.push(panelMain);
                }
            }
            hasUpdate: hasUpdate
            updateDownloadUrl: updateDownloadUrl
        }
    }

    Component {
        id: panelChangelog

        LauncherChangeLog {
            onFinished: {
                launcherSettings.lastVersion = LAUNCHER_VERSION_CODE
                next()
            }
            hasUpdate: hasUpdate
        }
    }

    LauncherSettings {
        id: launcherSettings
    }

    MessageDialog {
        id: playDownloadError
        title: qsTr("Connecting to Google Play failed")
    }

    GooglePlayApi {
        id: playApi
        login: googleLoginHelperInstance

        onInitError: function(err) {
            playDownloadError.text = qsTr("Please login again, Details:<br/>%1").arg(err);
            playDownloadError.open()
        }

        onAppInfoFailed: function(error) {
            playDownloadError.text = qsTr("Failed to obtain the gameversion, please check your internet connection and / or login again");
            playDownloadError.open()
        }

        onTosApprovalRequired: function(tos, marketing) {
            googleTosApprovalWindow.tosText = tos
            googleTosApprovalWindow.marketingText = marketing
            googleTosApprovalWindow.show()
        }
    }

    GoogleVersionChannel {
        id: playVerChannel
        playApi: playApi
    }

    LauncherSettingsWindow {
        id: launcherSettingsWindow
        googleLoginHelper: googleLoginHelperInstance
        versionManager: versionManagerInstance
    }

    GameLogWindow {
        id: gameLogWindow
        launcher: gameLauncher

        MessageDialog {
            id: errorDialog
            title: "Launcher Error"
        }
    }

    TroubleshooterWindow {
        id: troubleshooterWindow
        googleLoginHelper: googleLoginHelperInstance
    }

    MessageDialog {
        id: corruptedInstallDialog
        title: "Unsupported Minecraft Version"
        text: "Your previously downloaded Minecraft Version might be unsupported or just corrupted.<br/><b>if you wanted to play a Beta or a new Release please wait patiently for an update,<br/>please choose a compatible version from the profile Editor</b><br/>otherwise if you have updated the Launcher recently.<br/>e.g. a crash please delete it in Settings,<br/>then download it again via the updated Launcher."
    }

    GameLauncher {
        id: gameLauncher
        onLaunchFailed: {
            exited();
            showLaunchError("Could not execute the game launcher. Please make sure it's dependencies are properly installed.<br><a href=\"https://github.com/ChristopherHX/linux-packaging-scripts/releases/tag/appimage\">Click here for more information Linux (Description)</a><br>This means for macOS you cannot use this launcher")
        }
        onStateChanged: {
            if (!running)
                exited();
            if (crashed) {
                application.setVisibleInDock(true);
                gameLogWindow.show()
                gameLogWindow.requestActivate()
            }
        }
        onCorruptedInstall: {
            corruptedInstallDialog.open()
        }
        function exited() {
            application.setVisibleInDock(true);
            window.show();
        }
    }

    MessageDialog {
        id: closeRunningDialog
        title: qsTr("Game is running")
        text: qsTr("Minecraft is currently running. Would you like to forcibly close it?\nHint: Press ignore to just close the Launcher UI")
        standardButtons: StandardButton.Ignore | StandardButton.Yes | StandardButton.No
        modality: Qt.ApplicationModal

        onYes: {
            gameLauncher.kill()
            application.quit()
        }

        onAccepted: {
            if(window.visible) {
                window.hide();
            }
            if(gameLogWindow.visible) {
                gameLogWindow.hide();
            }
        }
    }

    MessageDialog {
        id: restartDialog
        title: qsTr("Please restart")
        text: qsTr("Update finished, please restart the AppImage")
    }

    UpdateChecker {
        id: updateChecker

        onUpdateAvailable: {
            hasUpdate = true
            updateDownloadUrl = downloadUrl
        }
        onProgress: downloadProgress.value = progress
        onRequestRestart: {
            restartDialog.open()
        }
    }

    Connections {
        target: googleLoginHelperInstance
        onAccountInfoChanged: {
            if (googleLoginHelperInstance.account !== null)
                playApi.handleCheckinAndTos()
        }
        onLoginError: function(err) {
            playDownloadError.text = qsTr("The Launcher failed to sign you in\nPlease login again\n%1").arg(err);
            playDownloadError.open()
        }
    }


    Connections {
        target: window
        onClosing: {
            if(!gameLogWindow.visible) {
                if (gameLauncher.running) {
                    close.accepted = false
                    closeRunningDialog.open()
                } else {
                    application.quit();
                }
            }
        }
    }

    Connections {
        target: gameLogWindow
        onClosing: {
            if(!window.visible) {
                if (gameLauncher.running) {
                    close.accepted = false
                    closeRunningDialog.open()
                } else {
                    application.quit();
                }
            } else {
                gameLauncher.logDetached();
            }
        }
    }

    function needsToLogIn() {
        return googleLoginHelperInstance.account == null && versionManagerInstance.versions.size === 0
    }

    Component.onCompleted: {
        if(launcherSettings.checkForUpdates)
            updateChecker.checkForUpdates()
        playApi.handleCheckinAndTos()
        versionManagerInstance.downloadLists(googleLoginHelperInstance.getAbis(true))
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
