import QtQuick
import QtQuick.Window
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.folderlistmodel
import "Components"
import io.mrarm.mcpelauncher 1.0

BaseScreen {
    id: playScreen

    property GoogleLoginHelper googleLoginHelper
    property VersionManager versionManager
    property ProfileManager profileManager
    property GooglePlayApi playApi
    property GoogleVersionChannel playVerChannel

    property bool isVersionsInitialized: false
    property bool progressbarVisible: playDownloadTask.active || apkExtractionTask.active
    property bool hasUpdate: false
    property string updateDownloadUrl: ""
    property string warnMessage: ""
    property string warnUrl: ""

    property bool statusChecking: !isVersionsInitialized || playVerChannel.licenseStatus === 0 || playVerChannel.licenseStatus === 1
    property string activeVersionName: getDisplayedVersionName()
    property bool activeVersionNeedsDownload: needsDownload()
    property bool activeVersionSupported: checkSupport()

    headerContent: TabBar {
        background: null
        MTabButton {
            text: qsTr("Play")
        }
    }

    Image {
        id: backgroundArt
        Layout.fillWidth: true
        Layout.fillHeight: true
        source: wallpaperFolderModel.getRandomImage()
        smooth: sourceSize.height > 256
        fillMode: Image.PreserveAspectCrop

        FolderListModel {
            id: wallpaperFolderModel
            nameFilters: ["*.jpg", "*.jpeg", "*.png"]
            folder: launcherSettings.gameDataDir + "/background_art"
            showDirs: false
            showOnlyReadable: true
            function getRandomImage() {
                if (count > 0)
                    return "file://" + get(Math.random() * count, "filePath")
                return "qrc:/Resources/artwork0.png"
            }
        }

        Flickable {
            height: Math.min(parent.height, contentHeight)
            width: Math.min(parent.width - 30, 640)
            contentWidth: width
            contentHeight: notifyColumn.height
            x: (parent.width - width) / 2

            Column {
                id: notifyColumn
                width: parent.width
                spacing: 10
                topPadding: 15
                bottomPadding: 15

                NotifyBanner {
                    id: playStatusNotify

                    function actionViewLog() {
                        mainNavigation.updateIndex(3) // 3 = game log page
                    }
                    function actionSignIn() {
                        if (googleLoginHelper.account !== null) {
                            playVerChannel.playApi = null
                            playVerChannel.playApi = playApi
                        } else {
                            googleLoginHelper.acquireAccount(window)
                        }
                    }
                    function actionUnsupportedWiki() {
                        Qt.openUrlExternally("https://github.com/minecraft-linux/mcpelauncher-manifest/issues/797")
                    }
                    function actionRetryCheck() {
                        actionSignIn()
                    }

                    property var statusMsg: {
                        if (playScreen.statusChecking)
                            return {}
                        if (gameLauncher.running)
                            return {
                                "title": qsTr("Game is running"),
                                "description": qsTr("Exit game to edit or change profile."),
                                "actionText": qsTr("View log"),
                                "action": actionViewLog,
                                "color": "#262"
                            }
                        if (googleLoginHelper.account === null)
                            return {
                                "title": qsTr("Action required"),
                                "description": qsTr("Please sign into your Google Play account."),
                                "actionText": qsTr("Sign in"),
                                "action": actionSignIn
                            }
                        if ((!playVerChannel.hasVerifiedLicense && LAUNCHER_ENABLE_GOOGLE_PLAY_LICENCE_CHECK && !launcherSettings.trialMode) || (activeVersionNeedsDownload && playVerChannel.licenseStatus !== 3))
                            return {
                                "title": qsTr("Can't verify license"),
                                "description": qsTr("You should have purchased Minecraft%1 in your Google Play account to download it here. If you have used a wrong account, please sign out and sign in again.").arg(launcherSettings.trialMode ? " (Trial)" : ""),
                                "actionText": qsTr("Retry"),
                                "action": actionRetryCheck
                            }
                        if (!playScreen.activeVersionName)
                            return {}
                        if (!playScreen.activeVersionSupported)
                            return {
                                "title": qsTr("Unsupported version"),
                                "description": qsTr("The Minecraft version you have selected for the current profile is unsupported or untested. Support for new version is a feature request."),
                                "actionText": qsTr("See wiki"),
                                "action": actionUnsupportedWiki
                            }
                        if (activeVersionNeedsDownload && profileManager.activeProfile.versionType === ProfileInfo.LATEST_GOOGLE_PLAY && googleLoginHelper.hideLatest)
                            return {
                                "title": qsTr("Action required"),
                                "description": qsTr("Please sign in again into your Google Play account."),
                                "actionText": qsTr("Sign in"),
                                "action": actionSignIn
                            }
                        return {}
                    }

                    title: statusMsg.title || ""
                    description: statusMsg.description || ""
                    actionText: statusMsg.actionText || ""
                    color: statusMsg.color || "#832"
                    visible: !!statusMsg.title
                    dismissible: false
                    onClicked: {
                        if (statusMsg.action)
                            statusMsg.action()
                    }
                }

                NotifyBanner {
                    color: "#832"
                    title: qsTr("Warning")
                    description: warnMessage
                    actionText: playScreen.warnUrl ? qsTr("See Wiki") : ""
                    visible: warnMessage && launcherSettings.showNotifications
                    dismissible: false
                    onClicked: {
                        Qt.openUrlExternally(playScreen.warnUrl)
                    }
                }

                NotifyBanner {
                    color: "#444"
                    title: qsTr("Unconfigured Joysticks Found")
                    description: {
                        const ret = GamepadManager.gamepads.filter(gamepad => !gamepad.hasMapping).map(gamepad => gamepad.name)
                        if (ret.length === 1)
                            return qsTr("One Joystick cannot be used as Gamepad Input:\n%1.").arg(ret.join(", "))
                        return qsTr("%1 Joysticks cannot be used as Gamepad Input:\n%2.").arg(ret.length).arg(ret.join(", "))
                    }
                    actionText: "Configure"
                    visible: GamepadManager.gamepads.some(gamepad => !gamepad.hasMapping) && launcherSettings.showNotifications
                    onClicked: gamepadTool.show()
                }

                NotifyBanner {
                    color: "#652"
                    visible: launcherSettings.trialMode && launcherSettings.showNotifications
                    dismissible: false
                    title: qsTr("Trial Mode Enabled")
                    description: {
                        const msg = qsTr("Disable trial mode from settings to launch the full version instead. ")
                        return playVerChannel.licenseStatus == 4 ? qsTr("You must first buy \"Minecraft Trial\" on an Android device or VM to download it here. ") + msg : msg
                    }
                }

                NotifyBanner {
                    color: "#832"
                    title: qsTr("Play Version is behind")
                    description: qsTr("Google Play Version Channel is behind. Got %1. Expected %2.").arg(playVerChannel.latestVersion).arg(launcherLatestVersionBase().versionName)
                    visible: (googleLoginHelper.account !== null) && launcherLatestVersionBase().versionCode > playVerChannel.latestVersionCode && launcherSettings.showNotifications
                }

                NotifyBanner {
                    visible: hasUpdate && !(progressbarVisible || updateChecker.active) && launcherSettings.showNotifications
                    title: qsTr("Update available")
                    description: qsTr("A new version of the launcher is available.")
                    actionText: qsTr("Download")
                    onClicked: {
                        if (updateDownloadUrl.length == 0) {
                            updateCheckerConnectorBase.enabled = true
                            updateChecker.startUpdate()
                        } else {
                            Qt.openUrlExternally(updateDownloadUrl)
                        }
                    }
                }

                NotifyBanner {
                    color: "#832"
                    dismissible: false
                    title: qsTr("Error")
                    visible: (playApi.googleLoginError.length > 0 || playVerChannel.licenseStatus == 2) && launcherSettings.showNotifications
                    description: {
                        var msg = playApi.googleLoginError || playVerChannel.licenseStatus == 2 && qsTr("Access to the Google Play Apk Library has been rejected.")
                        if (!launcherSettings.trialMode && (playVerChannel.licenseStatus == 2))
                            msg += qsTr("\nYou can try this launcher for free by enabling the trial mode.")
                        return msg
                    }
                }
            }
        }
    }

    ProfileEditPopup {
        id: profileEditPopup
        onAboutToHide: profileComboBox.onAddProfileResult(profileEditPopup.profile)
        versionManager: playScreen.versionManager
        profileManager: playScreen.profileManager
        playVerChannel: playScreen.playVerChannel
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
                id: profileComboBox
                property bool loaded: false
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
                    if (loaded && currentProfile !== null)
                        profileManager.activeProfile = currentProfile
                }
                enabled: !(progressbarVisible || gameLauncher.running || googleLoginHelper.account === null)
            }

            MButton {
                Layout.preferredHeight: parent.height
                Layout.preferredWidth: parent.height
                z: hovered ? 1 : -1
                enabled: profileComboBox.enabled
                onClicked: {
                    profileEditPopup.setProfile(profileComboBox.getProfile())
                    profileEditPopup.open()
                }
                Image {
                    anchors.centerIn: parent
                    source: "qrc:/Resources/icon-edit.svg"
                    height: 24
                    width: 24
                    opacity: enabled ? 1.0 : 0.3
                }
            }
        }

        PlayButton {
            id: pbutton
            x: parent.width > 700 ? (parent.width - width) / 2 : (parent.width - width - 12)
            y: 54 - height
            width: Math.min(Math.max(Math.max(implicitWidth, 230), playScreen.width / 4), 320)
            Layout.alignment: Qt.AlignHCenter
            text: {
                if (playScreen.statusChecking || !playScreen.activeVersionName)
                    return ""
                return (playScreen.activeVersionNeedsDownload ? qsTr("Download and play") : qsTr("Play")).toUpperCase()
            }
            subText: {
                if (playScreen.statusChecking)
                    return ""
                return playScreen.activeVersionName ? ("Minecraft " + playScreen.activeVersionName) : qsTr("Unknown")
            }
            enabled: !(gameLauncher.running || playScreen.statusChecking || progressbarVisible || updateChecker.active || !playScreen.activeVersionSupported || !playScreen.activeVersionName || playStatusNotify.visible)
            onClicked: {
                if (playScreen.activeVersionNeedsDownload) {
                    playDownloadTask.versionCode = getDownloadVersionCode()
                    if (playDownloadTask.versionCode === 0)
                        return

                    progressBar.value = 0
                    const rawname = getRawVersionsName()
                    const partialDownload = !needsFullDownload(rawname)
                    if (partialDownload)
                        apkExtractionTask.versionName = rawname

                    playDownloadTask.start(partialDownload)
                } else {
                    launchGame()
                }
            }
        }
    }

    MProgressBar {
        id: progressBar
        property bool showProgressbar: progressbarVisible || updateChecker.active
        Layout.fillWidth: true
        label: {
            if (playDownloadTask.active)
                return qsTr("Downloading Minecraft...")
            if (apkExtractionTask.active)
                return qsTr("Extracting Minecraft...")
            return qsTr("Please wait...")
        }
        visible: showProgressbar || closeAnim.running
        indeterminate: value < 0.005

        states: State {
            name: "visible"
            when: progressBar.showProgressbar
        }

        transitions: [
            Transition {
                to: "visible"
                NumberAnimation {
                    target: progressBar
                    property: "Layout.preferredHeight"
                    to: 35
                    duration: 200
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: progressBar
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 100
                }
            },
            Transition {
                id: closeAnim
                to: "*"
                NumberAnimation {
                    target: progressBar
                    property: "Layout.preferredHeight"
                    to: 0
                    duration: 200
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: progressBar
                    property: "opacity"
                    to: 0
                    duration: 100
                }
            }
        ]
    }

    GoogleApkDownloadTask {
        id: playDownloadTask
        playApi: playScreen.playApi
        packageName: launcherSettings.trialMode ? "com.mojang.minecrafttrialpe" : "com.mojang.minecraftpe"
        keepApks: launcherSettings.downloadOnly || launcherSettings.keepApks
        onProgress: {
            progressBar.value = progress
        }
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
        versionManager: playScreen.versionManager
        onProgress: {
            progressBar.value = progress
        }
        allowIncompatible: launcherSettings.showUnsupported
        onError: function (err) {
            playDownloadError.text = qsTr("Error while extracting the downloaded file(s), <a href=\"https://github.com/minecraft-linux/mcpelauncher-ui-manifest/issues\">please report this error</a>: %1").arg(err)
            playDownloadError.open()
        }
        onFinished: launchGame()
        allowedPackages: {
            var packages = ["com.mojang.minecrafttrialpe", "com.mojang.minecraftedu"]
            if (!launcherSettings.trialMode)
                packages.push("com.mojang.minecraftpe")
            return packages
        }
    }

    MessageDialog {
        id: updateError
        title: "Update Error"
    }

    Connections {
        id: updateCheckerConnectorBase
        target: updateChecker
        enabled: false
        function onUpdateError(error) {
            updateCheckerConnectorBase.enabled = false
            updateError.text = error
            updateError.open()
        }
        function onProgress() {
            progressBar.value = progress
        }
    }

    /* utility functions */
    function launcherLatestVersion() {
        const showBeta = playVerChannel.latestVersionIsBeta && launcherSettings.showBetaVersions
        const versions = showBeta ? versionManager.archivalVersions.versions : versionManager.archivalVersions.versions.filter(ver => !ver.isBeta)

        const abis = googleLoginHelper.getAbis(launcherSettings.showUnsupported)
        console.log("launcherAbis: " + JSON.stringify(abis))

        const latestVersion = versions.find(ver => abis.includes(ver.abi))
        if (latestVersion) {
            console.log("launcherLatestVersion: " + JSON.stringify(latestVersion))
            return latestVersion
        }

        console.log(abis.length === 0 ? "Unsupported Device" : "Bug: No version")

        return null
    }

    function launcherLatestVersionBase() {
        return launcherLatestVersion() ?? {
            "versionName": "Invalid",
            "versionCode": 0
        }
    }

    function launcherLatestVersionscode() {
        console.log("Query version")
        if (!isVersionsInitialized) {
            return 0
        }
        if (checkGooglePlayLatestSupport()) {
            console.log("Use play version")
            return playScreen.playVerChannel.latestVersionCode
        } else {
            console.log("Use compat version")
            const ver = launcherLatestVersion()
            return ver ? ver.versionCode : 0
        }
    }

    function needsDownload() {
        const profile = profileManager.activeProfile
        if (profile.versionType == ProfileInfo.LATEST_GOOGLE_PLAY)
            return !versionManager.versions.contains(launcherLatestVersionscode())
        if (profile.versionType == ProfileInfo.LOCKED_CODE) {
            const dver = versionManager.versions.get(profile.versionCode)
            return !dver || !launcherSettings.showUnsupported && !versionManager.checkSupport(dver)
        }
        if (profile.versionType == ProfileInfo.LOCKED_NAME)
            return false
        return false
    }

    function getRawVersionsName() {
        const profile = profileManager.activeProfile
        if (profile.versionType == ProfileInfo.LATEST_GOOGLE_PLAY) {
            return getDisplayedNameForCode(launcherLatestVersionscode())
        }
        if (profile.versionType == ProfileInfo.LOCKED_CODE) {
            const ver = findArchivalVersion(profile.versionCode)
            if (ver !== null) {
                return ver.versionName
            }
        }
        return null
    }

    /* Skip downloading assets, only download missing native libs */
    function needsFullDownload(vername) {
        if (!vername)
            return true
        return !versionManager.versions.getAll().some(version => version.versionName === vername)
    }

    function findArchivalVersion(code) {
        const versions = versionManager.archivalVersions.versions
        for (var i = versions.length - 1; i >= 0; --i) {
            if (versions[i].versionCode === code || versions[i].versionCode === (code - 1000000000))
                return versions[i]
        }
        return null
    }

    function getDisplayedNameForCode(code) {
        const archiveInfo = findArchivalVersion(code)
        const ver = versionManager.versions.get(code)
        if (archiveInfo !== null && (ver === null || ver.archs.length === 1 && ver.archs[0] === archiveInfo.abi)) {
            return archiveInfo.versionName + " (" + archiveInfo.abi + ((archiveInfo.isBeta ? ", beta" : "") + ")")
        }
        if (code === playScreen.playVerChannel.latestVersionCode)
            return playScreen.playVerChannel.latestVersion + (playVerChannel.latestVersionIsBeta ? " (beta)" : "")
        if (ver !== null) {
            const profile = profileManager.activeProfile
            return qsTr("%1  (%2, %3)").arg(ver.versionName).arg(code).arg(profile.arch.length ? profile.arch : ver.archs.join(", "))
        }
    }

    function getDisplayedVersionName() {
        const profile = profileManager.activeProfile
        if (profile.versionType === ProfileInfo.LATEST_GOOGLE_PLAY)
            return getDisplayedNameForCode(launcherLatestVersionscode()) || ("Unknown (" + launcherLatestVersionscode() + ")")
        if (profile.versionType === ProfileInfo.LOCKED_CODE)
            return getDisplayedNameForCode(profile.versionCode) || ((profile.versionDirName ? profile.versionDirName : "Unknown") + " (" + profile.versionCode + ")")
        if (profile.versionType === ProfileInfo.LOCKED_NAME)
            return profile.versionDirName || "Unknown Version"
        return "Unknown"
    }

    function getDownloadVersionCode() {
        const profile = profileManager.activeProfile
        if (profile.versionType === ProfileInfo.LATEST_GOOGLE_PLAY)
            return launcherLatestVersionscode()
        if (profile.versionType === ProfileInfo.LOCKED_CODE)
            return profile.versionCode
        return null
    }

    function getCurrentGameDir(profile) {
        if (profile.versionType === ProfileInfo.LATEST_GOOGLE_PLAY)
            return versionManager.getDirectoryFor(versionManager.versions.get(launcherLatestVersionscode()))
        if (profile.versionType === ProfileInfo.LOCKED_CODE)
            return versionManager.getDirectoryFor(versionManager.versions.get(profile.versionCode))
        if (profile.versionType === ProfileInfo.LOCKED_NAME)
            return versionManager.getDirectoryFor(profile.versionDirName)
        return null
    }

    // Tests if it really works
    function checkLauncherLatestSupport() {
        const latestCode = launcherLatestVersionscode()
        return versionManager.archivalVersions.versions.length === 0 || launcherSettings.showUnsupported || (launcherSettings.showUnverified || findArchivalVersion(latestCode) !== null || checkRollForward(latestCode))
    }

    function checkRollForward(code) {
        return versionManager.archivalVersions.rollforwardVersionRange.some(range => range.minVersionCode <= code && code <= range.maxVersionCode)
    }

    // Tests for raw Google Play latest (previous default, always true)
    function checkGooglePlayLatestSupport() {
        if (versionManager.archivalVersions.versions.length === 0) {
            console.log("Bug errata 1")
            playScreen.warnMessage = qsTr("mcpelauncher-versiondb not loaded. Cannot check Minecraft version compatibility.")
            playScreen.warnUrl = ""
            return true
        }

        if (launcherSettings.showUnsupported || versionManager.archivalVersions.versions.length === 0) {
            console.log("Bug errata 2")
            return true
        }

        // Handle latest is beta, beta isn't enabled
        if (playVerChannel.latestVersionIsBeta && !launcherSettings.showBetaVersions) {
            playScreen.warnMessage = qsTr("Latest Minecraft Version %1 is a beta version, which is hidden by default.").arg(playVerChannel.latestVersion + (playVerChannel.latestVersionIsBeta ? " (beta)" : ""))
            playScreen.warnUrl = "https://github.com/minecraft-linux/mcpelauncher-manifest/issues/797"
            return false
        }

        if (launcherSettings.showUnverified) {
            console.log("Bug errata 3")
            return true
        }

        if (checkRollForward(playVerChannel.latestVersionCode))
            return true

        const archiveInfo = findArchivalVersion(playVerChannel.latestVersionCode)
        if (archiveInfo !== null) {
            if (playVerChannel.latestVersionIsBeta && (launcherSettings.showBetaVersions || launcherSettings.showUnsupported) || !archiveInfo.isBeta) {
                if (googleLoginHelper.getAbis(launcherSettings.showUnsupported).includes(archiveInfo.abi)) {
                    playScreen.warnMessage = ""
                    playScreen.warnUrl = ""
                    return true
                }
            }
        }

        playScreen.warnMessage = qsTr("Compatibility for latest Minecraft version %1 is unknown. Support for new Minecraft versions is a feature request.").arg(playVerChannel.latestVersion + (playVerChannel.latestVersionIsBeta ? " (beta)" : ""))
        playScreen.warnUrl = "https://github.com/minecraft-linux/mcpelauncher-manifest/issues/797"
        return false
    }

    function checkSupport() {
        const profile = profileManager.activeProfile

        if (profile.versionType === ProfileInfo.LATEST_GOOGLE_PLAY)
            return checkLauncherLatestSupport()

        if (profile.versionType === ProfileInfo.LOCKED_CODE) {
            const dver = versionManager.versions.get(profile.versionCode)
            if (dver && dver.archs.length > 0 && launcherSettings.showUnsupported)
                return true

            const ver = findArchivalVersion(profile.versionCode)
            if (ver !== null && (playVerChannel.latestVersionIsBeta && (launcherSettings.showBetaVersions || launcherSettings.showUnsupported) || !ver.isBeta)) {
                if (googleLoginHelper.getAbis(launcherSettings.showUnsupported).includes(ver.abi))
                    return true
            }

            return launcherSettings.showUnverified || launcherSettings.showUnsupported
        }

        if (profile.versionType === ProfileInfo.LOCKED_NAME)
            return launcherSettings.showUnsupported || launcherSettings.showUnverified && versionManager.checkSupport(profile.versionDirName)

        console.log("Failed")
        return false
    }

    function showLaunchError(message) {
        errorDialog.text = message.toString()
        errorDialog.open()
    }

    function launchGame() {
        const profile = profileManager.activeProfile

        if (gameLauncher.running) {
            showLaunchError("The game is already running.")
            return
        }

        gameLauncher.profile = profile

        const gameDir = getCurrentGameDir(profile)
        console.log("Game dir = " + gameDir)
        if (gameDir === null || gameDir.length <= 0) {
            showLaunchError("Could not find the game directory.")
            return
        }
        gameLauncher.gameDir = gameDir

        if (launcherSettings.startHideLauncher) {
            window.hide()
            application.setVisibleInDock(false)
        }

        gameLauncher.start(launcherSettings.disableGameLog, profile.arch, !launcherSettings.trialMode)
    }
}
