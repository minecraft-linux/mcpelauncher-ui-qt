import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.2
import QtQuick.Controls 2.2
import "ThemedControls"
import io.mrarm.mcpelauncher 1.0

ColumnLayout {

    property GoogleLoginHelper googleLoginHelper
    property VersionManager versionManager
    property ProfileManager profileManager
    property bool hasUpdate: false
    property string updateDownloadUrl: ""
    property bool ignoregameisrunning: false

    id: rowLayout
    spacing: 0

    Image {
        id: title
        smooth: false
        fillMode: Image.Tile
        source: "qrc:/Resources/noise.png"
        Layout.alignment: Qt.AlignTop
        Layout.fillWidth: true
        Layout.preferredHeight: 100

        RowLayout {
            anchors.fill: parent

            ColumnLayout {

                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                Image {
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    source: "qrc:/Resources/proprietary/minecraft.svg"
                    sourceSize.height: 44
                }

                Text {
                    color: "#ffffff"
                    text: qsTr("Unofficial Linux Launcher")
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    font.pixelSize: 16
                }

            }

        }


        MButton {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 20
            implicitWidth: 48
            implicitHeight: 48
            onClicked: launcherSettingsWindow.show()
            Image {
                anchors.centerIn: parent
                source: "qrc:/Resources/icon-settings.png"
                smooth: false
            }
        }

    }

    Rectangle {
        Layout.alignment: Qt.AlignTop
        Layout.fillWidth: true
        Layout.preferredHeight: children[0].implicitHeight + 20
        color: "#BBDEFB"
        visible: hasUpdate

        Text {
            width: parent.width
            height: parent.height
            text: "A new version of the launcher is available. Click to download the update."
            color: "#0D47A1"
            font.pointSize: 9
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (updateDownloadUrl.length == 0) {
                    updateChecker.startUpdate()
                } else {
                    Qt.openUrlExternally(updateDownloadUrl)
                }
            }
        }
    }

    MinecraftNews {}

    Rectangle {
        Layout.alignment: Qt.AlignBottom
        Layout.fillWidth: true
        Layout.preferredHeight: childrenRect.height + 2 * 5
        color: "#fff"
        visible: playDownloadTask.active || apkExtractionTask.active || updateChecker.active

        Item {
            y: 5
            x: parent.width / 10
            width: parent.width * 8 / 10
            height: childrenRect.height

            MProgressBar {
                id: downloadProgress
                width: parent.width
            }

            Label {
                id: downloadStatus
                width: parent.width
                height: parent.height
                text: {
                    if (playDownloadTask.active)
                        return "Downloading Minecraft..."
                    if (apkExtractionTask.active)
                        return "Extracting Minecraft..."
                    return "Please wait..."
                }
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

        }
    }

    Image {
        id: bottomPanel
        smooth: false
        fillMode: Image.Tile
        source: "qrc:/Resources/noise.png"
        horizontalAlignment: Image.AlignBottom
        Layout.alignment: Qt.AlignBottom
        Layout.fillWidth: true
        Layout.preferredHeight: 100

        RowLayout {
            anchors.fill: parent

            ColumnLayout {
                Layout.leftMargin: 20

                Text {
                    text: "Profile"
                    color: "#fff"
                    font.pointSize: 10
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter

                    ProfileComboBox {
                        property bool loaded: false

                        id: profileComboBox
                        Layout.preferredWidth: 200
                        onAddProfileSelected: {
                            profileEditWindow.reset()
                            profileEditWindow.show()
                        }
                        Component.onCompleted: {
                            setProfile(profileManager.activeProfile)
                            loaded = true
                        }
                        onCurrentProfileChanged: {
                            if (loaded && currentProfile !== null)
                                profileManager.activeProfile = currentProfile
                        }
                    }

                    MButton {
                        implicitWidth: 36
                        Image {
                            anchors.centerIn: parent
                            source: "qrc:/Resources/icon-edit.png"
                            smooth: false
                        }

                        onClicked: {
                            profileEditWindow.setProfile(profileComboBox.getProfile())
                            profileEditWindow.show()
                        }
                    }

                }

            }

            PlayButton {
                Layout.alignment: Qt.AlignHCenter
                text: (gameLauncher.running ? "Open log" : (needsDownload() ? (googleLoginHelper.account !== null ? "Download and play" : "Sign in or import .apk") : "Play")).toUpperCase()
                subText: gameLauncher.running ? "Game is running" : (getDisplayedVersionName() ? ("Minecraft " + getDisplayedVersionName()).toUpperCase() : "Please wait...")
                Layout.maximumWidth: 400
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                Layout.leftMargin: width / 6
                Layout.rightMargin: width / 6
                onClicked: {
                    if(gameLauncher.running) {
                        gameLogWindow.show();
                        gameLauncher.logAttached();
                    } else {
                        if (needsDownload()) {
                            if (googleLoginHelper.account === null) {
                                launcherSettingsWindow.show();
                                return;
                            }
                            playDownloadTask.versionCode = getDownloadVersionCode()
                            if (playDownloadTask.versionCode === 0)
                                return;

                            downloadProgress.value = 0
                            playDownloadTask.start()
                            return;
                        }
                        launchGame()
                    }
                }
            }

        }

    }

    GooglePlayApi {
        id: playApi
        login: googleLoginHelper

        onInitError: function(err) {
            playDownloadError.text = err + "\nPlease login again";
            playDownloadError.open()
            googleLoginHelper.signOut();
        }

        onAppInfoReceived: function(pkg, versionStr, versionCode) {
            console.log("Got app info " + versionStr + " " + versionCode)
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

    GoogleApkDownloadTask {
        id: playDownloadTask
        playApi: playApi
        packageName: "com.mojang.minecraftpe"
        onProgress: downloadProgress.value = progress
        onError: function(err) {
            playDownloadError.text = err;
            playDownloadError.open()
        }
        onFinished: {
            apkExtractionTask.sources = filePaths
            apkExtractionTask.start()
        }
    }

    MessageDialog {
        id: playDownloadError
        title: "Download failed"
    }

    ApkExtractionTask {
        id: apkExtractionTask
        versionManager: rowLayout.versionManager
        onProgress: downloadProgress.value = progress
        onError: function(err) {
            playDownloadError.text = "Error while extracting the downloaded file(s): " + err
            playDownloadError.open()
        }
        onFinished: function() {
            launchGame()
        }
    }

    EditProfileWindow {
        id: profileEditWindow
        versionManager: versionManagerInstance
        profileManager: profileManagerInstance
        playVerChannel: playVerChannel
        modality: Qt.WindowModal

        onClosing: {
            profileComboBox.onAddProfileResult(profileEditWindow.profile)
        }

    }

    LauncherSettingsWindow {
        id: launcherSettingsWindow
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
    }

    MessageDialog {
        id: corruptedInstallDialog
        title: "Please reinstall"
        text: "Your previously downloaded Minecraft Version is corrupted, please delete it in Settings then download it again via the updated Launcher"
    }

    GameLauncher {
        id: gameLauncher
        onLaunchFailed: {
            exited();
            showLaunchError("Could not find or execute the game launcher. Please make sure it's properly installed (it must exist in the PATH variable used when starting this program and you need 32bit support for running older 32bit versions (macOS Catalina (10.15+) is unsupported, it lacks 32bit support)).<br><a href=\"https://mcpelauncher.readthedocs.io/en/latest/troubleshooting.html#could-not-find-the-game-launcher\">Click here for help and additional information.</a>")
        }
        onStateChanged: {
            if (!running)
                exited();
            if (crashed) {
                application.setVisibleInDock(true);
                gameLogWindow.show()
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
        title: "Game is running"
        text: "Minecraft is currently running. Would you like to forcibly close it?"
        standardButtons: StandardButton.Ignore | StandardButton.Yes | StandardButton.No
        modality: Qt.ApplicationModal

        onYes: {
            gameLauncher.kill()
            application.quit()
        }

        onAccepted: {
            ignoregameisrunning = true;
            if(window.visible) {
                window.close();
            } else if(gameLogWindow.visible) {
                gameLogWindow.close();
            }
        }
    }

    MessageDialog {
        id: restartDialog
        title: "Please restart"
        text: "Update finished, please restart the AppImage"
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

    MessageDialog {
        id: warnUnsupportedABIDialog
    }

    Connections {
        target: googleLoginHelper
        onAccountInfoChanged: {
            if (googleLoginHelper.account !== null)
                playApi.handleCheckinAndTos()
            versionManager.downloadLists(googleLoginHelper.getDeviceStateABIs())
        }
        onWarnUnsupportedABI: function(abis, unsupported) {
            warnUnsupportedABIDialog.title = unsupported ? "Minecraft Android cannot run on your PC" : "Please change device settings"
            warnUnsupportedABIDialog.text = unsupported ? "Your Device isn't capable of running Android Software with this Launcher": "Your device or launcher isn't compatible with the currently device settings of your current google login\nPlease switch the Android ABI (architecture) in Settings and login again\nUnsupported Android ABI's for this device are " + abis.join(", ")
            warnUnsupportedABIDialog.open()
        }
    }

    Connections {
        target: window
        onClosing:
        {
            if(!ignoregameisrunning) {
                if (!gameLogWindow.visible && gameLauncher.running) {
                    close.accepted = false
                    closeRunningDialog.open()
                } else if (!gameLauncher.running && !gameLogWindow.visible) {
                    application.quit();
                }
            } else {
                ignoregameisrunning = false;
            }
        }
    }

    Connections {
        target: gameLogWindow
        onClosing: {
            if(!ignoregameisrunning) {
                if (!window.visible && gameLauncher.running) {
                    close.accepted = false
                    closeRunningDialog.open()
                } else if (!gameLauncher.running && !window.visible) {
                    application.quit();
                } else {
                    gameLauncher.logDetached();
                }
            } else {
                ignoregameisrunning = false;
                gameLauncher.logDetached();
            }
        }
    }

    Connections {
        target: application
        onClosing: {
            if (gameLauncher.running) {
                close.accepted = false
                closeRunningDialog.open()
            }
        }
    }

    Component.onCompleted: {
        if(launcherSettings.checkForUpdates)
            updateChecker.sendRequest()
        playApi.handleCheckinAndTos()
        versionManager.downloadLists(googleLoginHelper.getDeviceStateABIs())
    }


    /* utility functions */

    function needsDownload() {
        var profile = profileManager.activeProfile;
        if (profile.versionType == ProfileInfo.LATEST_GOOGLE_PLAY)
            return !versionManager.versions.contains(playVerChannel.latestVersionCode);
        if (profile.versionType == ProfileInfo.LOCKED_CODE)
            return !versionManager.versions.contains(profile.versionCode);
        if (profile.versionType == ProfileInfo.LOCKED_NAME)
            return false;
        return false;
    }

    function findArchivalVersion(code) {
        var versions = versionManager.archivalVersions.versions;
        for (var i = versions.length - 1; i >= 0; --i) {
            if (versions[i].versionCode === code)
                return versions[i];
        }
        return null;
    }

    function getDisplayedNameForCode(code) {
        var archiveInfo = findArchivalVersion(code);
        if (archiveInfo !== null)
            return archiveInfo.versionName + " (" + archiveInfo.abi + ((archiveInfo.isBeta ? ", beta" : "") +  ")");
        if (code === playVerChannel.latestVersionCode)
            return playVerChannel.latestVersion;
        return "Unknown";
    }

    function getDisplayedVersionName() {
        var profile = profileManager.activeProfile;
        if (profile.versionType === ProfileInfo.LATEST_GOOGLE_PLAY)
            return getDisplayedNameForCode(playVerChannel.latestVersionCode);
        if (profile.versionType === ProfileInfo.LOCKED_CODE)
            return getDisplayedNameForCode(profile.versionCode);
        if (profile.versionType === ProfileInfo.LOCKED_NAME)
            return profile.versionDirName;
        return "Unknown";
    }

    function getDownloadVersionCode() {
        var profile = profileManager.activeProfile;
        if (profile.versionType === ProfileInfo.LATEST_GOOGLE_PLAY)
            return playVerChannel.latestVersionCode;
        if (profile.versionType === ProfileInfo.LOCKED_CODE)
            return profile.versionCode;
        return null;
    }

    function getCurrentGameDir() {
        var profile = profileManager.activeProfile;
        if (profile.versionType === ProfileInfo.LATEST_GOOGLE_PLAY)
            return versionManager.getDirectoryFor(versionManager.versions.get(playVerChannel.latestVersionCode));
        if (profile.versionType === ProfileInfo.LOCKED_CODE)
            return versionManager.getDirectoryFor(versionManager.versions.get(profile.versionCode));
        if (profile.versionType === ProfileInfo.LOCKED_NAME)
            return versionManager.getDirectoryFor(profile.versionDirName);
        return null;
    }


    function showLaunchError(message) {
        errorDialog.text = message
        errorDialog.open();
    }

    function launchGame() {
        if (gameLauncher.running) {
            showLaunchError("The game is already running.")
            return;
        }

        gameLauncher.profile = profileManager.activeProfile;
        var gameDir = getCurrentGameDir();
        console.log("Game dir = " + gameDir);
        if (gameDir === null || gameDir.length <= 0) {
            showLaunchError("Could not find the game directory.")
            return;
        }
        gameLauncher.gameDir = gameDir
        if (launcherSettings.startHideLauncher)
            window.hide();
        if (launcherSettings.startOpenLog) {
            gameLogWindow.show();
            gameLauncher.logAttached();
        }
        if (launcherSettings.startHideLauncher && !launcherSettings.startOpenLog)
            application.setVisibleInDock(false);
        gameLauncher.start(launcherSettings.disableGameLog);
    }

}
