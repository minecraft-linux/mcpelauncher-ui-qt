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
    property bool isVersionsInitialized: false

    StackView {
        id: stackView
        anchors.fill: parent
    }


    GoogleLoginHelper {
        id: googleLoginHelperInstance
        includeIncompatible: launcherSettings.showUnsupported
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
            isVersionsInitialized: window.isVersionsInitialized
            playVerChannelInstance: playVerChannel
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
            hasUpdate: window.hasUpdate
            updateDownloadUrl: window.updateDownloadUrl
        }
    }

    Component {
        id: panelChangelog

        LauncherChangeLog {
            onFinished: {
                launcherSettings.lastVersion = LAUNCHER_VERSION_CODE
                next()
            }
            hasUpdate: window.hasUpdate
            updateDownloadUrl: window.updateDownloadUrl
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
            title: qsTr("Launcher Error")
        }
    }

    TroubleshooterWindow {
        id: troubleshooterWindow
        googleLoginHelper: googleLoginHelperInstance
    }

    GoogleTosApprovalWindow {
        id: googleTosApprovalWindow

        onDone: playApi.setTosApproved(approved, marketing)
    }

    MessageDialog {
        id: corruptedInstallDialog
        title: qsTr("Unsupported Minecraft Version")
        text: qsTr("The Minecraft Version you are trying to run is unsupported.<br/><b>if you wanted to play a new Release please wait patiently for an update,<br/>please choose a compatible version from the profile Editor</b>")
    }

    GameLauncher {
        id: gameLauncher
        onLaunchFailed: {
            exited();
            showLaunchError(qsTr("Could not execute the game launcher. Please make sure it's dependencies are properly installed.<br><a href=\"%1\">Click here for more information Linux</a>").arg("https://github.com/minecraft-linux/mcpelauncher-manifest/issues/796"))
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
            window.hasUpdate = true
            window.updateDownloadUrl = downloadUrl
        }
        onRequestRestart: {
            restartDialog.open()
        }
    }

    Connections {
        target: googleLoginHelperInstance
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
        return googleLoginHelperInstance.account == null && versionManagerInstance.versions.size === 0;
    }

    Component.onCompleted: {
        if(launcherSettings.checkForUpdates) {
            updateChecker.checkForUpdates();
        }
        versionManagerInstance.archivalVersions.versionsChanged.connect(function() {
            isVersionsInitialized = true;
            console.log("Versionslist initialized");
        });
        versionManagerInstance.downloadLists(googleLoginHelperInstance.getAbis(true), launcherSettings.versionsFeedBaseUrl);
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

    function showLaunchError(message) {
        errorDialog.text = message
        errorDialog.open();
    }

}
