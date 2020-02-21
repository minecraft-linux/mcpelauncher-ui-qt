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
            onClicked: Qt.openUrlExternally(updateDownloadUrl)
        }
    }

    MinecraftNews {}

    Rectangle {
        Layout.alignment: Qt.AlignBottom
        Layout.fillWidth: true
        Layout.preferredHeight: childrenRect.height + 2 * 5
        color: "#fff"
        visible: playDownloadTask.active || apkExtractionTask.active

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
                text: (needsDownload() ? (googleLoginHelper.account !== null ? "Download and play" : "Sign in or import .apk") : "Play").toUpperCase()
                subText: getDisplayedVersionName() ? ("Minecraft " + getDisplayedVersionName()).toUpperCase() : "Please wait..."
                Layout.maximumWidth: 400
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                Layout.leftMargin: width / 6
                Layout.rightMargin: width / 6
                onClicked: {
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

    GooglePlayApi {
        id: playApi
        login: googleLoginHelper

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

    GoogleTosApprovalWindow {
        id: googleTosApprovalWindow

        onDone: playApi.setTosApproved(approved, marketing)
    }

    EditProfileWindow {
        id: profileEditWindow
        versionManager: versionManagerInstance
        profileManager: profileManagerInstance
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

    GameLauncher {
        id: gameLauncher
        onLaunchFailed: {
            exited();
            showLaunchError("Could not find the game launcher. Please make sure it's properly installed (it must exist in the PATH variable used when starting this program).<br><a href=\"https://mcpelauncher.readthedocs.io/en/latest/troubleshooting.html#could-not-find-the-game-launcher\">Click here for help and additional information.</a>")
        }
        onStateChanged: {
            if (!running)
                exited();
            if (crashed) {
                application.setVisibleInDock(true);
                gameLogWindow.show()
            }
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
        standardButtons: StandardButton.Yes | StandardButton.No
        modality: Qt.ApplicationModal

        onYes: {
            gameLauncher.kill()
            application.quit()
        }
    }

    UpdateChecker {
        id: updateChecker

        onUpdateAvailable: {
            hasUpdate = true
            updateDownloadUrl = downloadUrl
        }
    }

    Connections {
        target: googleLoginHelper
        onAccountInfoChanged: {
            if (googleLoginHelper.account !== null)
                playApi.handleCheckinAndTos()
        }
    }

    Connections {
        target: window
        onClosing: onWindowClose(window)
    }

    Connections {
        target: gameLogWindow
        onClosing: onWindowClose(gameLogWindow)
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
        updateChecker.sendRequest()
        playApi.handleCheckinAndTos()
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
            return archiveInfo.versionName + (archiveInfo.isBeta ? " (beta)" : "");
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
        if (launcherSettings.startOpenLog)
            gameLogWindow.show();
        if (launcherSettings.startHideLauncher && !launcherSettings.startOpenLog)
            application.setVisibleInDock(false);
        gameLauncher.start();
    }

    function onWindowClose(target) {
        if (!gameLauncher.running &&
                (target !== this || !this.visible) &&
                (target !== gameLogWindow && !gameLogWindow.visible))
            application.quit();
    }

}
