import QtQuick
import QtQuick.Window
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.platform
import Qt.labs.folderlistmodel
import "Components"
import io.mrarm.mcpelauncher 1.0

BaseScreen {
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

    headerContent: TabBar {
        background: null
        MTabButton {
            text: qsTr("Play")
        }
    }

    Rectangle {
        Layout.alignment: Qt.AlignTop
        Layout.fillWidth: true
        Layout.preferredHeight: children[0].implicitHeight + 20
        color: "#b62"
        visible: {
            if (!launcherSettings.showNotifications) {
                return false
            }
            return playApiInstance.googleLoginError.length > 0 || playVerChannel.licenseStatus == 2
        }
        z: 2

        Text {
            width: parent.width
            height: parent.height
            text: {
                return (playApiInstance.googleLoginError || playVerChannel.licenseStatus == 2 && qsTr("Access to the Google Play Apk Library has been rejected")) + (!launcherSettings.trialMode && (playVerChannel.licenseStatus == 2) ? qsTr("<br/>You can try this launcher for free by enabling the trial mode") : "")
            }
            color: "#fff"
            font.pointSize: 9
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
        }
    }

    Rectangle {
        Layout.alignment: Qt.AlignTop
        Layout.fillWidth: true
        Layout.preferredHeight: children[0].implicitHeight + 20
        color: "#b62"
        visible: {
            if (!launcherSettings.showNotifications) {
                return false
            }
            return launcherSettings.trialMode
        }
        z: 2

        Text {
            width: parent.width
            height: parent.height
            text: {
                return qsTr("Disable Trial Mode to launch the full version") + (playVerChannel.licenseStatus == 4 ? qsTr(", you also have to buy the trial for free on an android device/vm to download it here") : "")
            }
            color: "#fff"
            font.pointSize: 9
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
        }
    }

    /* utility functions */
    function launcherLatestVersionBase() {
        var abis = googleLoginHelper.getAbis(launcherSettings.showUnsupported)
        for (var i = 0; i < versionManager.archivalVersions.versions.length; i++) {
            var ver = versionManager.archivalVersions.versions[i]
            if (playVerChannel.latestVersionIsBeta && launcherSettings.showBetaVersions || !ver.isBeta) {
                for (var j = 0; j < abis.length; j++) {
                    if (ver.abi === abis[j]) {
                        return ver
                    }
                }
            }
        }
        if (abis.length == 0) {
            console.log("Unsupported Device")
        } else {
            console.log("Bug: No version")
        }
        return {
            "versionName": "Invalid",
            "versionCode": 0
        }
    }

    Rectangle {
        Layout.alignment: Qt.AlignTop
        Layout.fillWidth: true
        Layout.preferredHeight: children[0].implicitHeight + 20
        color: "#b62"
        visible: {
            if (!launcherSettings.showNotifications || googleLoginHelper.account == null) {
                return false
            }
            return launcherLatestVersionBase().versionCode > playVerChannelInstance.latestVersionCode
        }
        z: 2

        Text {
            width: parent.width
            height: parent.height
            text: {
                return qsTr("Google Play Version Channel is behind %1 expected %2").arg(playVerChannelInstance.latestVersion).arg(launcherLatestVersionBase().versionName)
            }
            color: "#fff"
            font.pointSize: 9
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
        }
    }

    Image {
        Layout.fillWidth: true
        Layout.fillHeight: true
        id: backgroundArt
        anchors.fill: parent
        source: wallpaperFolderModel.getRandomImage()
        smooth: true
        fillMode: Image.PreserveAspectCrop
        FolderListModel {
            id: wallpaperFolderModel
            nameFilters: ["*.jpg", "*.jpeg", "*.png"]
            folder: launcherSettings.gameDataDir + "/background_art"
            showDirs: false
            showOnlyReadable: true

            function getRandomImage() {
                if (count > 0) {
                    return "file://" + get(Math.random() * count, "filePath")
                }
                return "qrc:/Resources/noise.png"
            }
        }
    }

    ProfileEditPopup {
        id: profileEditPopup
        onAboutToHide: profileComboBox.onAddProfileResult(profileEditPopup.profile)
        versionManager: rowLayout.versionManager
        profileManager: rowLayout.profileManager
        playVerChannel: rowLayout.playVerChannel
    }

    Rectangle {
        color: '#282828'
        Layout.fillWidth: true
        height: 66

        RowLayout {
            spacing: -1
            anchors.verticalCenter: parent.verticalCenter
            height: 44
            x: 10

            ProfileComboBox {
                property bool loaded: false
                id: profileComboBox
                Layout.preferredWidth: 170
                Layout.fillHeight: true
                onAddProfileSelected: {
                    profileEditPopup.reset()
                    profileEditPopup.open()
                }
                Component.onCompleted: {
                    setProfile(profileManager.activeProfile)
                    window.currentGameDataDir = Qt.binding(function () {
                        return (profileManager.activeProfile && profileManager.activeProfile.dataDirCustom) ? QmlUrlUtils.localFileToUrl(profileManager.activeProfile.dataDir) : ""
                    })
                    loaded = true
                }
                onCurrentProfileChanged: {
                    if (loaded && currentProfile !== null) {
                        profileManager.activeProfile = currentProfile
                    }
                }

                enabled: !(playDownloadTask.active || apkExtractionTask.active || gameLauncher.running)
            }

            MButton {
                Layout.preferredHeight: parent.height
                Layout.preferredWidth: parent.height
                z: hovered ? 1 : -1
                Image {
                    anchors.centerIn: parent
                    source: "qrc:/Resources/icon-edit.svg"
                    height: 24
                    width: 24
                    opacity: enabled ? 1.0 : 0.3
                }
                enabled: !(playDownloadTask.active || apkExtractionTask.active || gameLauncher.running)
                onClicked: {
                    profileEditPopup.setProfile(profileComboBox.getProfile())
                    profileEditPopup.open()
                }
            }
        }

        PlayButton {
            id: pbutton
            x: parent.width > 700 ? (parent.width - width) / 2 : (parent.width - width - 12)
            y: 54 - height
            width: Math.min(Math.max(Math.max(implicitWidth, 230), rowLayout.width / 4), 320)
            Layout.alignment: Qt.AlignHCenter
            property bool canDownload: googleLoginHelper.account !== null && playVerChannel.licenseStatus == 3

            text: (isVersionsInitialized && (playVerChannel.licenseStatus !== 0 && playVerChannel.licenseStatus !== 1) /* Fail or Succeeded */
                   ) ? ((playVerChannel.hasVerifiedLicense || launcherSettings.trialMode || !LAUNCHER_ENABLE_GOOGLE_PLAY_LICENCE_CHECK) && (canDownload || !needsDownload()) ? (gameLauncher.running ? qsTr("Game is running") : (checkSupport() ? (needsDownload() ? (googleLoginHelper.account !== null ? (profileManager.activeProfile.versionType === ProfileInfo.LATEST_GOOGLE_PLAY && googleLoginHelper.hideLatest ? qsTr("Please sign in again") : qsTr("Download and play")) : qsTr("Sign in")) : qsTr("Play")) : qsTr("Unsupported Version"))).toUpperCase() : googleLoginHelper.account !== null ? qsTr("Ask Google Again") : qsTr("Sign In")) : qsTr("Please wait...")
            subText: (isVersionsInitialized && (playVerChannel.licenseStatus !== 0 && playVerChannel.licenseStatus !== 1) /* Fail or Succeeded */
                      ) ? ((playVerChannel.hasVerifiedLicense || !LAUNCHER_ENABLE_GOOGLE_PLAY_LICENCE_CHECK) ? (gameLauncher.running ? "" : (getDisplayedVersionName() ? ("Minecraft " + getDisplayedVersionName()).toUpperCase() : qsTr("Please wait..."))) : "Failed to obtain apk url") : "..."
            enabled: !gameLauncher.running && (isVersionsInitialized && (playVerChannel.licenseStatus !== 0 && playVerChannel.licenseStatus !== 1) /* Fail or Succeeded */
                                               ) && !(playDownloadTask.active || apkExtractionTask.active || updateChecker.active || !checkSupport()) && (getDisplayedVersionName())

            onClicked: {
                if ((!playVerChannel.hasVerifiedLicense || !canDownload && needsDownload()) && LAUNCHER_ENABLE_GOOGLE_PLAY_LICENCE_CHECK) {
                    if (googleLoginHelper.account !== null) {
                        playVerChannel.playApi = null
                        playVerChannel.playApi = playApiInstance
                    } else {
                        googleLoginHelper.acquireAccount(window)
                    }
                } else {
                    if (needsDownload()) {
                        playDownloadTask.versionCode = getDownloadVersionCode()
                        if (playDownloadTask.versionCode === 0)
                            return

                        setProgressbarValue(0)
                        var rawname = getRawVersionsName()
                        var partialDownload = !needsFullDownload(rawname)
                        if (partialDownload) {
                            apkExtractionTask.versionName = rawname
                        }
                        playDownloadTask.start(partialDownload)
                        return
                    }
                    launchGame()
                }
            }
        }
    }

    GoogleApkDownloadTask {
        id: playDownloadTask
        playApi: playApiInstance
        packageName: launcherSettings.trialMode ? "com.mojang.minecrafttrialpe" : "com.mojang.minecraftpe"
        keepApks: launcherSettings.downloadOnly || launcherSettings.keepApks
        onProgress: setProgressbarValue(progress)
        onError: function (err) {
            if (playDownloadError.visible) {
                playDownloadError.text += "\n" + err
            } else {
                playDownloadError.text = err
                playDownloadError.open()
            }
        }
        onFinished: {
            if (!launcherSettings.downloadOnly) {
                apkExtractionTask.sources = filePaths
                apkExtractionTask.start()
            }
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
        onError: function (err) {
            playDownloadError.text = qsTr("Error while extracting the downloaded file(s), <a href=\"https://github.com/minecraft-linux/mcpelauncher-ui-manifest/issues\">please report this error</a>: %1").arg(err)
            playDownloadError.open()
        }
        onFinished: function () {
            launchGame()
        }
        allowedPackages: {
            var packages = ["com.mojang.minecrafttrialpe", "com.mojang.minecraftedu"]
            if (!launcherSettings.trialMode) {
                packages.push("com.mojang.minecraftpe")
            }
            return packages
        }
    }

    /* utility functions */
    function launcherLatestVersion() {
        var abis = googleLoginHelper.getAbis(launcherSettings.showUnsupported)
        console.log("launcherLatestVersion: " + JSON.stringify(abis))
        for (var i = 0; i < versionManager.archivalVersions.versions.length; i++) {
            var ver = versionManager.archivalVersions.versions[i]
            if (playVerChannel.latestVersionIsBeta && launcherSettings.showBetaVersions || !ver.isBeta) {
                for (var j = 0; j < abis.length; j++) {
                    if (ver.abi === abis[j]) {
                        console.log("launcherLatestVersion: " + JSON.stringify(ver))
                        return ver
                    }
                }
            }
        }
        if (abis.length == 0) {
            console.log("Unsupported Device")
        } else {
            console.log("Bug: No version")
        }
        return null
    }

    function launcherLatestVersionscode() {
        console.log("Query version")
        if (!isVersionsInitialized) {
            return 0
        }
        if (checkGooglePlayLatestSupport()) {
            console.log("Use play version")

            return rowLayout.playVerChannel.latestVersionCode
        } else {
            console.log("Use compat version")
            var ver = launcherLatestVersion()
            return ver ? ver.versionCode : 0
        }
    }

    function needsDownload() {
        var profile = profileManager.activeProfile
        if (profile.versionType == ProfileInfo.LATEST_GOOGLE_PLAY)
            return !versionManager.versions.contains(launcherLatestVersionscode())
        if (profile.versionType == ProfileInfo.LOCKED_CODE) {
            var dver = versionManager.versions.get(profile.versionCode)
            return !dver || !launcherSettings.showUnsupported && !versionManager.checkSupport(dver)
        }
        if (profile.versionType == ProfileInfo.LOCKED_NAME)
            return false
        return false
    }

    function getRawVersionsName() {
        var profile = profileManager.activeProfile
        if (profile.versionType == ProfileInfo.LATEST_GOOGLE_PLAY) {
            return getDisplayedNameForCode(launcherLatestVersionscode())
        }
        if (profile.versionType == ProfileInfo.LOCKED_CODE) {
            var ver = findArchivalVersion(profile.versionCode)
            if (ver != null) {
                return ver.versionName
            }
        }
        return null
    }

    /* Skip downloading assets, only download missing native libs */
    function needsFullDownload(vername) {
        if (vername != null) {
            var versions = versionManager.versions.getAll()
            for (var i = 0; i < versions.length; ++i) {
                if (versions[i].versionName === vername)
                    return false
            }
        }
        return true
    }

    function findArchivalVersion(code) {
        var versions = versionManager.archivalVersions.versions
        for (var i = versions.length - 1; i >= 0; --i) {
            if (versions[i].versionCode === code || versions[i].versionCode === (code - 1000000000))
                return versions[i]
        }
        return null
    }

    function getDisplayedNameForCode(code) {
        var archiveInfo = findArchivalVersion(code)
        var ver = versionManager.versions.get(code)
        if (archiveInfo !== null && (ver === null || ver.archs.length == 1 && ver.archs[0] == archiveInfo.abi)) {
            return archiveInfo.versionName + " (" + archiveInfo.abi + ((archiveInfo.isBeta ? ", beta" : "") + ")")
        }
        if (code === rowLayout.playVerChannel.latestVersionCode)
            return rowLayout.playVerChannel.latestVersion + (playVerChannel.latestVersionIsBeta ? " (beta)" : "")
        if (ver !== null) {
            var profile = profileManager.activeProfile
            return qsTr("%1  (%2, %3)").arg(ver.versionName).arg(code).arg(profile.arch.length ? profile.arch : ver.archs.join(", "))
        }
    }

    function getDisplayedVersionName() {
        var profile = profileManager.activeProfile
        if (profile.versionType === ProfileInfo.LATEST_GOOGLE_PLAY)
            return getDisplayedNameForCode(launcherLatestVersionscode()) || ("Unknown (" + launcherLatestVersionscode() + ")")
        if (profile.versionType === ProfileInfo.LOCKED_CODE)
            return getDisplayedNameForCode(profile.versionCode) || ((profile.versionDirName ? profile.versionDirName : "Unknown") + " (" + profile.versionCode + ")")
        if (profile.versionType === ProfileInfo.LOCKED_NAME)
            return profile.versionDirName || "Unknown Version"
        return "Unknown"
    }

    function getDownloadVersionCode() {
        var profile = profileManager.activeProfile
        if (profile.versionType === ProfileInfo.LATEST_GOOGLE_PLAY) {
            return launcherLatestVersionscode()
        }
        if (profile.versionType === ProfileInfo.LOCKED_CODE)
            return profile.versionCode
        return null
    }

    function getCurrentGameDir(profile) {
        if (profile.versionType === ProfileInfo.LATEST_GOOGLE_PLAY) {
            return versionManager.getDirectoryFor(versionManager.versions.get(launcherLatestVersionscode()))
        }
        if (profile.versionType === ProfileInfo.LOCKED_CODE)
            return versionManager.getDirectoryFor(versionManager.versions.get(profile.versionCode))
        if (profile.versionType === ProfileInfo.LOCKED_NAME)
            return versionManager.getDirectoryFor(profile.versionDirName)
        return null
    }

    // Tests if it really works
    function checkLauncherLatestSupport() {
        var latestCode = launcherLatestVersionscode()
        return versionManager.archivalVersions.versions.length == 0 || launcherSettings.showUnsupported || (launcherSettings.showUnverified || findArchivalVersion(latestCode) != null || checkRollForward(latestCode))
    }

    function checkRollForward(code) {
        var rollfwds = versionManager.archivalVersions.rollforwardVersionRange
        for (var i = 0; i < rollfwds.length; i++) {
            console.log(JSON.stringify(rollfwds[i]))
            if (rollfwds[i].minVersionCode <= code && code <= rollfwds[i].maxVersionCode) {
                return true
            }
        }
        return false
    }

    // Tests for raw Google Play latest (previous default, always true)
    function checkGooglePlayLatestSupport() {
        if (versionManager.archivalVersions.versions.length == 0) {
            console.log("Bug errata 1")
            rowLayout.warnMessage = qsTr("No mcpelauncher-versiondb loaded cannot check support")
            rowLayout.warnUrl = ""
            return true
        }
        if (launcherSettings.showUnsupported || versionManager.archivalVersions.versions.length === 0) {
            console.log("Bug errata 2")
            return true
        }
        // Handle latest is beta, beta isn't enabled
        if (playVerChannel.latestVersionIsBeta && !launcherSettings.showBetaVersions) {
            rowLayout.warnMessage = qsTr("Latest Minecraft Version %1 is a beta version, which are hidden by default (Click here for more Information)").arg(playVerChannel.latestVersion + (playVerChannel.latestVersionIsBeta ? " (beta)" : ""))
            rowLayout.warnUrl = "https://github.com/minecraft-linux/mcpelauncher-manifest/issues/797"
            return false
        }
        if (launcherSettings.showUnverified) {
            console.log("Bug errata 3")
            return true
        }
        if (checkRollForward(playVerChannel.latestVersionCode)) {
            return true
        }
        var archiveInfo = findArchivalVersion(playVerChannel.latestVersionCode)
        if (archiveInfo != null) {
            var abis = googleLoginHelper.getAbis(launcherSettings.showUnsupported)
            if (playVerChannel.latestVersionIsBeta && (launcherSettings.showBetaVersions || launcherSettings.showUnsupported) || !archiveInfo.isBeta) {
                for (var j = 0; j < abis.length; j++) {
                    if (archiveInfo.abi === abis[j]) {
                        rowLayout.warnMessage = ""
                        rowLayout.warnUrl = ""
                        return true
                    }
                }
            }
        }
        rowLayout.warnMessage = qsTr("Latest Minecraft Version %1 compatibility is Unknown, supporting new Minecraft Versions is a feature Request (Click here for more Information)").arg(playVerChannel.latestVersion + (playVerChannel.latestVersionIsBeta ? " (beta)" : ""))
        rowLayout.warnUrl = "https://github.com/minecraft-linux/mcpelauncher-manifest/issues/797"
        return false
    }

    function checkSupport() {
        var profile = profileManager.activeProfile
        if (profile.versionType === ProfileInfo.LATEST_GOOGLE_PLAY) {
            return checkLauncherLatestSupport()
        }
        if (profile.versionType === ProfileInfo.LOCKED_CODE) {
            var dver = versionManager.versions.get(profile.versionCode)
            if (dver && dver.archs.length > 0 && launcherSettings.showUnsupported) {
                return true
            } else {
                var abis = googleLoginHelper.getAbis(launcherSettings.showUnsupported)
                var ver = findArchivalVersion(profile.versionCode)
                if (ver !== null && (playVerChannel.latestVersionIsBeta && (launcherSettings.showBetaVersions || launcherSettings.showUnsupported) || !ver.isBeta)) {
                    for (var j = 0; j < abis.length; j++) {
                        if (ver.abi === abis[j]) {
                            return true
                        }
                    }
                }
                return launcherSettings.showUnverified || launcherSettings.showUnsupported
            }
        }
        if (profile.versionType === ProfileInfo.LOCKED_NAME) {
            return launcherSettings.showUnsupported || launcherSettings.showUnverified && versionManager.checkSupport(profile.versionDirName)
        }
        console.log("Failed")
        return false
    }

    function showLaunchError(message) {
        errorDialog.text = message.toString()
        errorDialog.open()
    }

    function launchGame() {
        if (gameLauncher.running) {
            showLaunchError("The game is already running.")
            return
        }

        gameLauncher.profile = profileManager.activeProfile
        var gameDir = getCurrentGameDir(profileManager.activeProfile)
        console.log("Game dir = " + gameDir)
        if (gameDir === null || gameDir.length <= 0) {
            showLaunchError("Could not find the game directory.")
            return
        }
        gameLauncher.gameDir = gameDir
        if (launcherSettings.startHideLauncher)
            window.hide()
        if (launcherSettings.startHideLauncher)
            application.setVisibleInDock(false)
        var profile = profileManager.activeProfile
        gameLauncher.start(launcherSettings.disableGameLog, profile.arch, !launcherSettings.trialMode)
    }
}
