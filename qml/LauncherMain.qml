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
    property bool hidden: false

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

            Layout.minimumWidth: profilesettingsbox.leftMargin + profilesettingsbox.implicitWidth + pbutton.minimumWidth

            ColumnLayout {
                id: profilesettingsbox
                Layout.leftMargin: 20

                property var createProfileEditWindow: function () {
                    var component = Qt.createComponent("EditProfileWindow.qml")
                    var obj = component.createObject(rowLayout, {versionManager: rowLayout.versionManager, profileManager: rowLayout.profileManager, playVerChannel: playVerChannel, modality: Qt.WindowModal})
                    obj.closing.connect(function() {
                        profileComboBox.onAddProfileResult(obj.profile)
                    })
                    return obj;
                }
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
                            var window = profilesettingsbox.createProfileEditWindow()
                            window.reset()
                            window.show()
                        }
                        Component.onCompleted: {
                            setProfile(profileManager.activeProfile)
                            loaded = true
                        }
                        onCurrentProfileChanged: {
                            if (loaded && currentProfile !== null)
                                profileManager.activeProfile = currentProfile
                        }

                        enabled: !(playDownloadTask.active || apkExtractionTask.active || gameLauncher.running)
                    }

                    MButton {
                        implicitWidth: 36
                        Image {
                            anchors.centerIn: parent
                            source: "qrc:/Resources/icon-edit.png"
                            smooth: false
                            opacity: enabled ? 1.0 : 0.3
                        }
                        enabled: !(playDownloadTask.active || apkExtractionTask.active || gameLauncher.running)

                        onClicked: {
                            var window = profilesettingsbox.createProfileEditWindow()
                            window.setProfile(profileComboBox.getProfile())
                            window.show()
                        }
                    }

                }

            }

            PlayButton {
                id: pbutton
                Layout.alignment: Qt.AlignHCenter
                text: (gameLauncher.running ? "Open log" : (needsDownload() ? (googleLoginHelper.account !== null ? (profileManager.activeProfile.versionType === ProfileInfo.LATEST_GOOGLE_PLAY && googleLoginHelper.hideLatest ? "Please sign in again" : "Download and play") : "Sign in or import .apk") : checkSupport() ? "Play" : "Unsupported Version")).toUpperCase()
                subText: gameLauncher.running ? "Game is running" : (getDisplayedVersionName() ? ("Minecraft " + getDisplayedVersionName()).toUpperCase() : "Please wait...")
                Layout.maximumWidth: 400
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                Layout.leftMargin: width / 6
                Layout.rightMargin: width / 6
                Layout.minimumWidth: implicitWidth
                Layout.minimumHeight: implicitHeight
                enabled: !(playDownloadTask.active || apkExtractionTask.active || updateChecker.active || (needsDownload() ? googleLoginHelper.account !== null && profileManager.activeProfile.versionType === ProfileInfo.LATEST_GOOGLE_PLAY && googleLoginHelper.hideLatest : !checkSupport())) && (gameLauncher.running || getDisplayedVersionName())

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
            }
        }
        onCorruptedInstall: {
            corruptedInstallDialog.open()
        }
        function exited() {
            if (gameLauncher.running) {
                console.log("still running or not?");
            } else {
                console.log("showing again");
                application.setVisibleInDock(true);
                hidden = false
                window.show();
            }
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
            hidden = true
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
            versionManager.downloadLists(googleLoginHelper.getDeviceStateABIs(launcherSettings.showUnsupported))
        }
        onLoginError: function(err) {
            playDownloadError.text = err + "\nPlease login again";
            playDownloadError.open()
        }
    }

    Timer {
        id: hidetimer
        interval: 100; running: true; repeat: false
        onTriggered: if(window.visible && hidden) { window.hide() }
    }

    Connections {
        target: window
        onVisibleChanged: {
            // Takle auto showing bug
            hidetimer.restart()
        }
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

    Connections {
        target: application
        onClosing: {
            /*if (gameLauncher.running) {
                close.accepted = false
                closeRunningDialog.open()
            }*/
        }
    }

    Component.onCompleted: {
        if(launcherSettings.checkForUpdates)
            updateChecker.sendRequest()
        playApi.handleCheckinAndTos()
        versionManager.downloadLists(googleLoginHelper.getDeviceStateABIs(launcherSettings.showUnsupported))
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
        return "Unknown (" + code + ")";
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

    function checkSupport() {
        var profile = profileManager.activeProfile;
        if (profile.versionType === ProfileInfo.LATEST_GOOGLE_PLAY)
            return versionManager.checkSupport(versionManager.versions.get(playVerChannel.latestVersionCode));
        if (profile.versionType === ProfileInfo.LOCKED_CODE) {
            console.log(profile.versionCode)
            return versionManager.checkSupport(versionManager.versions.get(profile.versionCode));
        }
        if (profile.versionType === ProfileInfo.LOCKED_NAME) {
            console.log(profile.versionDirName)
            return versionManager.checkSupport(profile.versionDirName);
        }
        console.log("Failed")
        return false;
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
        hidden = launcherSettings.startHideLauncher
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
