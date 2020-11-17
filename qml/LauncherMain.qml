import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.2
import QtQuick.Controls 2.2
import "ThemedControls"
import io.mrarm.mcpelauncher 1.0

LauncherBase {

    property GoogleLoginHelper googleLoginHelper
    property VersionManager versionManager
    property ProfileManager profileManager
    property GooglePlayApi playApiInstance
    progressbarVisible: playDownloadTask.active || apkExtractionTask.active
    progressbarText: {
        if (playDownloadTask.active)
            return qsTr("Downloading Minecraft...")
        if (apkExtractionTask.active)
            return qsTr("Extracting Minecraft...")
        return qsTr("Please wait...")
    }

    id: rowLayout
    spacing: 0

    MinecraftNews {}

    bottomPanelContent: RowLayout {
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
                text: qsTr("Profile")
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
            text: (gameLauncher.running ? qsTr("Open log") : (checkSupport() ? (needsDownload() ? (googleLoginHelper.account !== null ? (profileManager.activeProfile.versionType === ProfileInfo.LATEST_GOOGLE_PLAY && googleLoginHelper.hideLatest ? qsTr("Please sign in again") : qsTr("Download and play")) : qsTr("Sign in or import .apk")) : qsTr("Play")) : qsTr("Unsupported Version"))).toUpperCase()
            subText: gameLauncher.running ? qsTr("Game is running") : (getDisplayedVersionName() ? ("Minecraft " + getDisplayedVersionName()).toUpperCase() : qsTr("Please wait..."))
            Layout.maximumWidth: 400
            Layout.fillWidth: true
            Layout.preferredHeight: 70
            Layout.leftMargin: width / 6
            Layout.rightMargin: width / 6
            Layout.minimumWidth: implicitWidth
            Layout.minimumHeight: implicitHeight
            enabled: !(playDownloadTask.active || apkExtractionTask.active || updateChecker.active || !checkSupport()) && (gameLauncher.running || getDisplayedVersionName())

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

                        setProgressbarValue(0)
                        var rawname = getRawVersionsName()
                        var partialDownload = !needsFullDownload(rawname)
                        if (partialDownload) {
                            apkExtractionTask.versionName = rawname
                        }
                        playDownloadTask.start(partialDownload)
                        return;
                    }
                    launchGame()
                }
            }
        }
    }

    GoogleApkDownloadTask {
        id: playDownloadTask
        playApi: playApiInstance
        packageName: "com.mojang.minecraftpe"
        onProgress: setProgressbarValue(progress)
        onError: function(err) {
            if (playDownloadError.visible) {
                playDownloadError.text += "\n" + err
            } else {
                playDownloadError.text = err;
                playDownloadError.open()
            }
        }
        onFinished: {
            apkExtractionTask.sources = filePaths
            apkExtractionTask.start()
        }
    }

    MessageDialog {
        id: playDownloadError
        title: qsTr("Download failed")
    }

    ApkExtractionTask {
        id: apkExtractionTask
        versionManager: rowLayout.versionManager
        onProgress: setProgressbarValue(progress)
        allowIncompatible: launcherSettings.showUnsupported
        onError: function(err) {
            playDownloadError.text = qsTr("Error while extracting the downloaded file(s), <a href=\"https://github.com/minecraft-linux/mcpelauncher-ui-manifest/issues\">please report this error</a>: %1").arg(err)
            playDownloadError.open()
        }
        onFinished: function() {
            launchGame()
        }
    }

    /* utility functions */

    function launcherLatestVersion() {
        for (var i = 0; i < versionManager.archivalVersions.versions.length; i++) {
            if (playVerChannel.latestVersionIsBeta && launcherSettings.showBetaVersions || !versionManager.archivalVersions.versions[i].isBeta) {
                return versionManager.archivalVersions.versions[i];
            }
        }
    }

    function launcherLatestVersionscode() {
        if (checkGooglePlayLatestSupport()) {
            return playVerChannel.latestVersionCode;
        } else {
            var ver = launcherLatestVersion();
            return ver ? ver.versionCode : 0;
        }
    }

    function needsDownload() {
        var profile = profileManager.activeProfile;
        if (profile.versionType == ProfileInfo.LATEST_GOOGLE_PLAY)
            return !versionManager.versions.contains(launcherLatestVersionscode());
        if (profile.versionType == ProfileInfo.LOCKED_CODE)
            return !versionManager.versions.contains(profile.versionCode);
        if (profile.versionType == ProfileInfo.LOCKED_NAME)
            return false;
        return false;
    }

    function getRawVersionsName() {
        var profile = profileManager.activeProfile;
        if (profile.versionType == ProfileInfo.LATEST_GOOGLE_PLAY) {
            return playVerChannel.latestVersion;
        }
        if (profile.versionType == ProfileInfo.LOCKED_CODE) {
            var ver = findArchivalVersion(profile.versionCode);
            if (ver != null) {
                return ver.versionName;
            }
        }
        return null;
    }

    /* Skip downloading assets, only download missing native libs */
    function needsFullDownload(vername) {
        if (vername != null) {
            var versions = versionManager.versions.getAll();
            for (var i = 0; i < versions.length; ++i) {
                if (versions[i].versionName === vername)
                    return false;
            }
        } 
        return true;
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
        var ver = versionManager.versions.get(code)
        if (archiveInfo !== null && (ver === null || ver.archs.length == 1 && ver.archs[0] == archiveInfo.abi)) {
            return archiveInfo.versionName + " (" + archiveInfo.abi + ((archiveInfo.isBeta ? ", beta" : "") +  ")");
        }
        if (code === playVerChannel.latestVersionCode)
            return playVerChannel.latestVersion + (playVerChannel.latestVersionIsBeta ? " (beta)" : "")
        if (ver !== null) {
            var profile = profileManager.activeProfile;
            return qsTr("%1  (%2, %3)").arg(ver.versionName).arg(code).arg(profile.arch.length ? profile.arch : ver.archs.join(", "));
        }
    }

    function getDisplayedVersionName() {
        var profile = profileManager.activeProfile;
        if (profile.versionType === ProfileInfo.LATEST_GOOGLE_PLAY)
            return getDisplayedNameForCode(launcherLatestVersionscode()) || ("Unknown (" + launcherLatestVersionscode() + ")");
        if (profile.versionType === ProfileInfo.LOCKED_CODE)
            return getDisplayedNameForCode(profile.versionCode) || ((profile.versionDirName ? profile.versionDirName : "Unknown") + " (" + profile.versionCode + ")");
        if (profile.versionType === ProfileInfo.LOCKED_NAME)
            return profile.versionDirName || "Unknown Version";
        return "Unknown";
    }

    function getDownloadVersionCode() {
        var profile = profileManager.activeProfile;
        if (profile.versionType === ProfileInfo.LATEST_GOOGLE_PLAY) {
            return launcherLatestVersionscode();
        }
        if (profile.versionType === ProfileInfo.LOCKED_CODE)
            return profile.versionCode;
        return null;
    }

    function getCurrentGameDir() {
        var profile = profileManager.activeProfile;
        if (profile.versionType === ProfileInfo.LATEST_GOOGLE_PLAY) {
            return versionManager.getDirectoryFor(versionManager.versions.get(launcherLatestVersionscode()));
        }
        if (profile.versionType === ProfileInfo.LOCKED_CODE)
            return versionManager.getDirectoryFor(versionManager.versions.get(profile.versionCode));
        if (profile.versionType === ProfileInfo.LOCKED_NAME)
            return versionManager.getDirectoryFor(profile.versionDirName);
        return null;
    }

    // Tests if it really works
    function checkLauncherLatestSupport() {
        var ver = versionManager.versions.get(launcherLatestVersionscode())
        return launcherSettings.showUnsupported || ((ver == null || versionManager.checkSupport(ver)) && (launcherSettings.showUnverified || findArchivalVersion(launcherLatestVersionscode()) != null));
    }

    // Tests for raw Google Play latest (previous default, allways true)
    function checkGooglePlayLatestSupport() {
        if (launcherSettings.showUnsupported || launcherSettings.showUnverified) {
            return true;
        }
        // Handle latest is beta, beta isn't enabled
        if (playVerChannel.latestVersionIsBeta && !launcherSettings.showBetaVersions) {
            return false;
        }
        var iver = versionManager.versions.get(playVerChannel.latestVersionCode)
        return versionManager.checkSupport(iver ? iver : findArchivalVersion(playVerChannel.latestVersionCode))
    }

    function checkSupport() {
        var profile = profileManager.activeProfile;
        if (profile.versionType === ProfileInfo.LATEST_GOOGLE_PLAY) {
            return checkLauncherLatestSupport();
        }
        if (profile.versionType === ProfileInfo.LOCKED_CODE) {
            var dver = versionManager.versions.get(profile.versionCode)
            if (dver) {
                return dver.archs.length > 0 && launcherSettings.showUnsupported || versionManager.checkSupport(dver)
            } else {
                var abis = googleLoginHelper.getAbis(launcherSettings.showUnsupported)
                var ver = findArchivalVersion(profile.versionCode)
                if (ver !== null && (playVerChannel.latestVersionIsBeta && (launcherSettings.showBetaVersions || launcherSettings.showUnsupported) || !ver.isBeta)) {
                    for (var j = 0; j < abis.length; j++) {
                        if (ver.abi === abis[j]) {
                            return true;
                        }
                    }
                }
                return launcherSettings.showUnverified || launcherSettings.showUnsupported;
            }
        }
        if (profile.versionType === ProfileInfo.LOCKED_NAME) {
            return launcherSettings.showUnsupported || versionManager.checkSupport(profile.versionDirName);
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
        if (launcherSettings.startHideLauncher)
            window.hide();
        if (launcherSettings.startOpenLog) {
            gameLogWindow.show();
            gameLauncher.logAttached();
        }
        if (launcherSettings.startHideLauncher && !launcherSettings.startOpenLog)
            application.setVisibleInDock(false);
        var profile = profileManager.activeProfile;
        gameLauncher.start(launcherSettings.disableGameLog, profile.arch);
    }
    
}
