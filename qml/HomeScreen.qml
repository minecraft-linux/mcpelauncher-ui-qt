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
    property var xprogress: null
    property bool progressbarVisible: xprogress || playDownloader.active || updateManager.active
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

    ModManager {
        id: modManager
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
                        if (launcherSettings.chromeOSMode && !googleLoginHelper.chromeOS) {
                            return {
                                "title": qsTr("ChromeOS Mode not supported"),
                                "description": qsTr("Your Google Play account doesn’t have the required license for ChromeOS Mode. If you don’t own a Chromebook, FydeOS may offer a one‑time option to purchase this license. Note that ChromeOS builds currently have Vibrant Visuals permanently disabled."),
                            }
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

// UpdateManager
                UpdateManager {
                    id: updateManager

                    property var active: false

                    onProgress: function(p) {
                        progressBar.value = p
                    }

                    versionList: versionManager.availableArchivalVersions
                    // Unqualified profileManager here had caused a recursion in some qt releases that may cause a crash
                    // profileManager: playScreen.profileManager
                    maxCompatVersion: 1

                    property var hasUpdate: false
                    property var update: null

                    Component.onCompleted: {
                        updateManager.checkForUpdates();
                    }

                    onUpdateFailed: {
                        updateManager.active = false;
                        updateManager.hasUpdate = false;
                        updateManager.checkForUpdates();
                    }
                    onUpdateAvailable: (mod, version, arch, url , metadata) => {
                        hasUpdate = true;
                        update = {mod, version, arch, url, metadata};
                    }

                    onFinished: {
                        updateManager.active = false;
                        activateMod();
                    }

                    function activateMod() {
                        var toggle = false;
                        var profileManager = playScreen.profileManager
                        var prefix = modManager.getRoot() + "/" + updateManager.update.mod + "/"
                        var abis = googleLoginHelper.getAbis(false)
                        var arch = profileManager.activeProfile.arch || abis.length > 0 && abis[0]
                        var entry = prefix + updateManager.update.version + "/" + arch + "/"

                        var has = profileManager.activeProfile.mods.includes(entry)
                        profileManager.activeProfile.mods = profileManager.activeProfile.mods.filter(function (e) {
                            return !e.startsWith(prefix)
                        })
                        if(!has || !toggle) {
                            profileManager.activeProfile.mods.push(entry)
                        }
                        console.log("Mods: " + JSON.stringify(profileManager.activeProfile.mods))
                        profileManager.activeProfile.save()
                    }
                }

                Connections {
                    target: profileManager.activeProfile
                    function onChanged() {
                        updateManager.hasUpdate = false;
                        updateManager.checkForUpdates();
                    }
                }
                Connections {
                    target: profileManager
                    function onActiveProfileChanged() {
                        updateManager.hasUpdate = false;
                        updateManager.checkForUpdates();
                    }
                }

                NotifyBanner {
                    visible: updateManager.hasUpdate && !(progressbarVisible || updateChecker.active) && launcherSettings.showNotifications
                    title: qsTr("DRM Update Available")
                    description: qsTr("To support additional versions up to %1.").arg(updateManager.update.version)
                    actionText: updateManager.update.url ? qsTr("Download") : qsTr("Activate")
                    onClicked: {
                        updateManager.hasUpdate = false;
                        if(updateManager.update.url) {
                            updateManager.active = true;
                            updateManager.downloadUpdate(updateManager.update.mod, updateManager.update.version, updateManager.update.arch, updateManager.update.url, updateManager.update.metadata);
                        } else {
                            updateManager.activateMod();
                        }
                    }
                }
/// UpdateManager END

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

                NotifyBanner {
                    id: banner
                    color: "#382"
                    dismissible: true
                    title: qsTr("Update")
                    visible: false

                    Component.onCompleted: {
                        if(!LAUNCHER_FLATPAK_CONFIG_URL || !launcherSettings.checkForUpdates || !launcherSettings.showNotifications) {
                            return;
                        }
                        var xhr = new XMLHttpRequest()
                        xhr.onreadystatechange = function() {
                            if (xhr.readyState === XMLHttpRequest.DONE) {
                                if (xhr.status === 200) {
                                    try {
                                        var json = JSON.parse(xhr.responseText)
                                        var modules = json["modules"] || []
                                        for (var i = 0; i < modules.length; i++) {
                                            var module = modules[i]
                                            if (module.name === "mcpelauncher-ui-manifest") {
                                                var opts = module["build-options"]?.["config-opts"] || []
                                                for (var j = 0; j < opts.length; j++) {
                                                    var match = opts[j].match(/-DLAUNCHER_VERSION_NAME=([^\s]+)/)
                                                    if (match && LAUNCHER_VERSION_NAME !== match[1]) {
                                                        banner.title = qsTr("Update available")
                                                        banner.description = "Available " + match[1] + " installed " + LAUNCHER_VERSION_NAME
                                                        banner.visible = true
                                                        return
                                                    }
                                                }
                                            }
                                        }
                                        console.log("Version name not found")
                                    } catch (e) {
                                        console.log("Failed to parse JSON:", e)
                                    }
                                } else {
                                    console.log("HTTP error:", xhr.status)
                                }
                            }
                        }

                        xhr.open("GET", LAUNCHER_FLATPAK_CONFIG_URL)
                        xhr.send()
                    }

                    actionText: qsTr("Update")
                    onClicked: {
                        Qt.openUrlExternally("https://minecraft-linux.github.io/#flatpak")
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

// Extra Version Code
    function onProfileChanged() {
        var profile = profileManager.activeProfile;
        console.log("Profile mods " + JSON.stringify(profile.mods))
        var extraVersions = [];
        for(var i = 0; i < profile.mods.length; i++) {
            console.log(" - " + profile.mods[i]);
            var modInfo = modManager.loadModInfoByPath(profile.mods[i]);
            console.log(JSON.stringify(modInfo));
            if(modInfo.metadata && modInfo.metadata.version && modInfo.metadata.version.extraVersions) {
                const abis = googleLoginHelper.getAbis(launcherSettings.showUnsupported);
                for(var abi of abis) {
                    extraVersions.push(...modInfo.metadata.version.extraVersions.filter(ver => ver.codes && ver.codes[abi]).map(v => (
                    {
                        versionName: v.version_name,
                        versionCode: v.codes[abi],
                        abi: abi,
                        isBeta: v.beta
                    })))
                    if(modInfo.metadata.version.provides) {
                        for(var compatVer = 1; compatVer <= LAUNCHER_VERSION_COMPAT; compatVer++) {
                            if(compatVer.toString() in modInfo.metadata.version.provides) {
                                extraVersions.push(...modInfo.metadata.version.provides[compatVer].extraVersions.filter(ver => ver.codes && ver.codes[abi]).map(v => (
                                {
                                    versionName: v.version_name,
                                    versionCode: v.codes[abi],
                                    abi: abi,
                                    isBeta: v.beta
                                })))
                            }
                        }
                    }
                }
            }
        }
        versionManager.setExtraVersions(extraVersions);
    }

    Connections {
        target: profileManager.activeProfile
        function onChanged() {
            onProfileChanged();
        }
    }
    Connections {
        target: profileManager
        function onActiveProfileChanged() {
            onProfileChanged();
        }
        Component.onCompleted: {
            onProfileChanged()
        }
    }
/////

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
                    if (loaded && currentProfile !== null) {
                        profileManager.activeProfile = currentProfile
                    }
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
            property var xhelper: XHelper {
            }
            id: pbutton
            x: parent.width > 700 ? (parent.width - width) / 2 : (parent.width - width - 12)
            y: 54 - height
            width: Math.min(Math.max(Math.max(implicitWidth, 230), playScreen.width / 4), 320)
            Layout.alignment: Qt.AlignHCenter
            text: {
                console.log("..")
                for(var x in xhelper.packages) {
                    console.log(x)
                    console.log(xhelper.packages[x].version)
                    var s = xhelper.packages[x].version.split(".")
                    return s[0] + "." + s[1] + "." + s[2] + "." + s[3];
                }
                return "....";
            }
            subText: "Minecraft for Windows"
            onClicked: {
                playScreen.xprogress = xhelper.downloadPackage("", "");
                progressBar.value = Qt.binding(function() { return playScreen.xprogress.progress / playScreen.xprogress.maximum })
                pbutton.subText = "Downloading..."
            }
        }
    }

    MProgressBar {
        id: progressBar
        property bool showProgressbar: progressbarVisible || updateChecker.active
        Layout.fillWidth: true
        label: {
            if (playDownloader.active)
                return playDownloader.label
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

    property var progressBarInstance: progressBar
    property var launcherSettingsInstance: launcherSettings

    PlayDownloader {
        id: playDownloader
        playApi: playScreen.playApi
        versionManager: playScreen.versionManager
        progressBar: playScreen.progressBarInstance
        launcherSettings: playScreen.launcherSettingsInstance
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
