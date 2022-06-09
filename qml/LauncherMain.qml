import QtQuick
import QtQuick.Window
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.platform
import "ThemedControls"
import io.mrarm.mcpelauncher 1.0

LauncherBase {

    property GoogleLoginHelper googleLoginHelper
    property VersionManager versionManager
    property ProfileManager profileManager
    property GooglePlayApi playApiInstance
    property GoogleVersionChannel playVerChannel
    property bool isVersionsInitialized: false
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
    EditProfileWindow {
       id: profileEditWindow
       onClosing: profileComboBox.onAddProfileResult(profileEditWindow.profile)
       versionManager: rowLayout.versionManager
       profileManager: rowLayout.profileManager
       playVerChannel: rowLayout.playVerChannel
       modality: Qt.WindowModal
    }

    bottomPanelContent: RowLayout {
        anchors.fill: parent

        Layout.minimumWidth: profilesettingsbox.leftMargin + profilesettingsbox.implicitWidth + pbutton.minimumWidth

        ColumnLayout {
            id: profilesettingsbox
            Layout.leftMargin: 20

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
                        profileEditWindow.reset()
                        profileEditWindow.show()
                    }
                    Component.onCompleted: {
                        setProfile(profileManager.activeProfile)
                        launcherSettingsWindow.currentGameDataDir = Qt.binding(function() { return (profileManager.activeProfile && profileManager.activeProfile.dataDirCustom) ? QmlUrlUtils.localFileToUrl(profileManager.activeProfile.dataDir) : "" });
                        loaded = true
                    }
                    onCurrentProfileChanged: {
                        if (loaded && currentProfile !== null) {
                            profileManager.activeProfile = currentProfile;
                        }
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
                        profileEditWindow.setProfile(profileComboBox.getProfile())
                        profileEditWindow.show()
                    }
                }

            }

        }

        PlayButton {
            id: pbutton
            Layout.alignment: Qt.AlignHCenter
            text: (isVersionsInitialized && playVerChannel.licenseStatus > 1 /* Fail or Succeeded */ ) ? ((googleLoginHelper.account !== null && playVerChannel.hasVerifiedLicense || !LAUNCHER_ENABLE_GOOGLE_PLAY_LICENCE_CHECK) ? (gameLauncher.running ? qsTr("Open log") : (checkSupport() ? (needsDownload() ? (googleLoginHelper.account !== null ? (profileManager.activeProfile.versionType === ProfileInfo.LATEST_GOOGLE_PLAY && googleLoginHelper.hideLatest ? qsTr("Please sign in again") : qsTr("Download and play")) : qsTr("Sign in")) : qsTr("Play")) : qsTr("Unsupported Version"))).toUpperCase() : qsTr("You have to own the game")) : qsTr("Please wait...")
            subText: (isVersionsInitialized && playVerChannel.licenseStatus > 1 /* Fail or Succeeded */ ) ? (gameLauncher.running ? qsTr("Game is running") : (getDisplayedVersionName() ? ("Minecraft " + getDisplayedVersionName()).toUpperCase() : qsTr("Please wait..."))) : "..."
            Layout.fillWidth: true
            Layout.preferredHeight: 70
            Layout.minimumHeight: implicitHeight
            enabled: (isVersionsInitialized && playVerChannel.licenseStatus > 1 /* Fail or Succeeded */ ) && !(playDownloadTask.active || apkExtractionTask.active || updateChecker.active || !checkSupport()) && (gameLauncher.running || getDisplayedVersionName()) && (googleLoginHelper.account !== null && playVerChannel.hasVerifiedLicense || !LAUNCHER_ENABLE_GOOGLE_PLAY_LICENCE_CHECK)

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
        var abis = googleLoginHelper.getAbis(launcherSettings.showUnsupported)
        for (var i = 0; i < versionManager.archivalVersions.versions.length; i++) {
            var ver = versionManager.archivalVersions.versions[i];
            if (playVerChannel.latestVersionIsBeta && launcherSettings.showBetaVersions || !ver.isBeta) {
                for (var j = 0; j < abis.length; j++) {
                    if (ver.abi === abis[j]) {
                        return ver;
                    }
                }
            }
        }
        if (abis.length == 0) {
            console.log("Unsupported Device");
        } else {
            console.log("Bug: No version");
        }
        return null;
    }

    function launcherLatestVersionscode() {
        console.log("Query version");
        if(!isVersionsInitialized) {
            return 0;
        }
        if (checkGooglePlayLatestSupport()) {
            console.log("Use play version");

            return rowLayout.playVerChannel.latestVersionCode;
        } else {
            console.log("Use compat version");
            var ver = launcherLatestVersion();
            return ver ? ver.versionCode : 0;
        }
    }

    function needsDownload() {
        var profile = profileManager.activeProfile;
        if (profile.versionType == ProfileInfo.LATEST_GOOGLE_PLAY)
            return !versionManager.versions.contains(launcherLatestVersionscode());
        if (profile.versionType == ProfileInfo.LOCKED_CODE) {
            var dver = versionManager.versions.get(profile.versionCode);
            return !dver || !versionManager.checkSupport(dver);
        }
        if (profile.versionType == ProfileInfo.LOCKED_NAME)
            return false;
        return false;
    }

    function getRawVersionsName() {
        var profile = profileManager.activeProfile;
        if (profile.versionType == ProfileInfo.LATEST_GOOGLE_PLAY) {
            return getDisplayedNameForCode(launcherLatestVersionscode());
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
        if (code === rowLayout.playVerChannel.latestVersionCode)
            return rowLayout.playVerChannel.latestVersion + (playVerChannel.latestVersionIsBeta ? " (beta)" : "")
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

    function getCurrentGameDir(profile) {
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
        return versionManager.archivalVersions.versions.length == 0 || launcherSettings.showUnsupported || (launcherSettings.showUnverified || findArchivalVersion(launcherLatestVersionscode()) != null);
    }

    // Tests for raw Google Play latest (previous default, allways true)
    function checkGooglePlayLatestSupport() {
        if(versionManager.archivalVersions.versions.length == 0) {
            console.log("Bug errata 1")
            rowLayout.warnMessage = qsTr("No mcpelauncher-versiondb loaded cannot check support")
            rowLayout.warnUrl = "";
            return true;
        }
        if (launcherSettings.showUnsupported || versionManager.archivalVersions.versions.length === 0) {
            console.log("Bug errata 2")
            return true;
        }
        // Handle latest is beta, beta isn't enabled
        if (playVerChannel.latestVersionIsBeta && !launcherSettings.showBetaVersions) {
            rowLayout.warnMessage = qsTr("Latest Minecraft Version %1 is a beta version, therefore not supported").arg(playVerChannel.latestVersion + (playVerChannel.latestVersionIsBeta ? " (beta)" : ""))
            rowLayout.warnUrl = "";
            return false;
        }
        if(launcherSettings.showUnverified) {
            console.log("Bug errata 3")
            return true;
        }
        var archiveInfo = findArchivalVersion(playVerChannel.latestVersionCode);
        if (archiveInfo != null) {
            var abis = googleLoginHelper.getAbis(launcherSettings.showUnsupported)
            if (playVerChannel.latestVersionIsBeta && (launcherSettings.showBetaVersions || launcherSettings.showUnsupported) || !archiveInfo.isBeta) {
                for (var j = 0; j < abis.length; j++) {
                    if (archiveInfo.abi === abis[j]) {
                        rowLayout.warnMessage = ""
                        rowLayout.warnUrl = "";
                        return true;
                    }
                }
            }
        }
        rowLayout.warnMessage = qsTr("Latest Minecraft Version %1 isn't supported yet, supporting new Minecraft Versions isn't a Bug, it is a feature Request (Click here for more Information)").arg(playVerChannel.latestVersion + (playVerChannel.latestVersionIsBeta ? " (beta)" : ""))
        rowLayout.warnUrl = "https://github.com/ChristopherHX/mcpelauncher-manifest/issues/48"
        return false;
    }

    function checkSupport() {
        var profile = profileManager.activeProfile;
        if (profile.versionType === ProfileInfo.LATEST_GOOGLE_PLAY) {
            return checkLauncherLatestSupport();
        }
        if (profile.versionType === ProfileInfo.LOCKED_CODE) {
            var dver = versionManager.versions.get(profile.versionCode)
            if (dver && dver.archs.length > 0 && launcherSettings.showUnsupported) {
                return true;
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
            return launcherSettings.showUnsupported || launcherSettings.showUnverified && versionManager.checkSupport(profile.versionDirName);
        }
        console.log("Failed")
        return false;
    }

    function showLaunchError(message) {
        errorDialog.text = message.toString()
        errorDialog.open();
    }

    function launchGame() {
        if (gameLauncher.running) {
            showLaunchError("The game is already running.")
            return;
        }

        gameLauncher.profile = profileManager.activeProfile;
        var gameDir = getCurrentGameDir(profileManager.activeProfile);
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
        gameLauncher.start(launcherSettings.disableGameLog, profile.arch, true);
    }
    
}
