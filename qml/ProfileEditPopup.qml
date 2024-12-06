import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Dialogs
import QtQuick.Controls
import Qt.labs.platform
import "Components"
import io.mrarm.mcpelauncher 1.0

Popup {
    property VersionManager versionManager
    property ProfileManager profileManager
    property GoogleVersionChannel playVerChannel
    property ProfileInfo profile: null
    property int targetHeight: Math.min(contentHeight, window.height - 20)
    id: popup
    modal: true
    clip: true
    padding: 0
    height: targetHeight
    anchors.centerIn: Overlay.overlay
    closePolicy: Popup.NoAutoClose
    focus: true

    background: Rectangle {
        color: "#333"
    }

    Overlay.modal: Rectangle {
        id: popupOverlay
        color: "#8f181818"
    }

    enter: Transition {
        NumberAnimation {
            property: "height"
            from: popup.targetHeight / 2
            to: popup.targetHeight
            duration: 150
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: 150
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: popupOverlay
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: 150
            easing.type: Easing.OutCubic
        }
    }

    exit: Transition {
        NumberAnimation {
            property: "height"
            to: popup.contentHeight / 2
            duration: 150
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            property: "opacity"
            to: 0
            duration: 150
            easing.type: Easing.OutCubic
        }
    }

    onClosed: {
        advancedColumn.visible = false
    }

    Behavior on height {
        PropertyAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }

    ColumnLayout {
        id: layout
        spacing: 0
        BaseHeader {
            id: baseHeader
            title: profile == null ? qsTr("Create profile") : qsTr("Edit profile")
            MButton {
                text: qsTr("Delete")
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 10
                visible: profile !== null && profile !== profileManager.defaultProfile
                onClicked: {
                    profileManager.deleteProfile(profile)
                    close()
                }
            }
        }

        ScrollView {
            id: scrollView
            implicitWidth: contentWidth
            implicitHeight: Math.min(contentHeight, window.height - baseHeader.height - 20)
            contentHeight: settings.implicitHeight + 40
            contentWidth: Math.min(560, window.width - 30)

            ColumnLayout {
                id: settings
                anchors.centerIn: parent
                width: scrollView.contentWidth - 40

                RowLayout {
                    spacing: 15
                    Layout.fillWidth: true
                    ColumnLayout {
                        Layout.fillWidth: true
                        MText {
                            text: qsTr("Name")
                            font.bold: true
                        }
                        MTextField {
                            id: profileName
                            Layout.fillWidth: true
                            placeholderText: "unamed"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        MText {
                            text: qsTr("Version")
                            font.bold: true
                        }
                        MComboBox {
                            id: profileVersion
                            textRole: "name"
                            model: versionsmodel
                            property var versions: versionManager.versions.getAll().sort(function (a, b) {
                                return b.versionCode - a.versionCode
                            })
                            property var archivalVersions: excludeInstalledVersions(versionManager.archivalVersions.versions)
                            property var extraVersionName: null
                            property var hideLatest: googleLoginHelper.hideLatest
                            property var data: []
                            property var update: () => {
                                                     data = []
                                                     versionsmodel.clear()
                                                     var abis = googleLoginHelper.getAbis(launcherSettings.showUnsupported)
                                                     var append = function (obj) {
                                                         data.push(obj)
                                                         versionsmodel.append({
                                                                                  "name": obj.name
                                                                              })
                                                     }
                                                     if (!hideLatest && googleLoginHelper.account !== null && playVerChannel.hasVerifiedLicense) {
                                                         var support = checkGooglePlayLatestSupport()
                                                         var latest = support ? playVerChannel.latestVersion : launcherLatestVersion().versionName
                                                         append({
                                                                    "name": qsTr("Latest %1 (%2)").arg((latest.length === 0 ? qsTr("version") : latest)).arg((support ? qsTr("Google Play") : qsTr("compatible"))),
                                                                    "versionType": ProfileInfo.LATEST_GOOGLE_PLAY
                                                                })
                                                     }
                                                     for (var i = 0; i < versions.length; i++) {
                                                         for (var j = 0; j < abis.length; j++) {
                                                             for (var k = 0; k < versions[i].archs.length; k++) {
                                                                 if (versions[i].archs[k] == abis[j]) {
                                                                     append({
                                                                                "name": qsTr("%1 (installed, %2)").arg(versions[i].versionName).arg(versions[i].archs[k]),
                                                                                "versionType": ProfileInfo.LOCKED_CODE,
                                                                                "obj": versions[i],
                                                                                "arch": versions[i].archs[k]
                                                                            })
                                                                     break
                                                                 }
                                                             }
                                                         }
                                                     }
                                                     if (!hideLatest && googleLoginHelper.account !== null && playVerChannel.hasVerifiedLicense) {
                                                         for (i = 0; i < archivalVersions.length; i++) {
                                                             for (var j = 0; j < abis.length; j++) {
                                                                 if (archivalVersions[i].abi == abis[j]) {
                                                                     append({
                                                                                "name": qsTr("%1 (%2%3)").arg(archivalVersions[i].versionName).arg(archivalVersions[i].abi).arg((archivalVersions[i].isBeta ? (qsTr(", ") + qsTr("beta")) : "")),
                                                                                "versionType": ProfileInfo.LOCKED_CODE,
                                                                                "obj": archivalVersions[i],
                                                                                "arch": archivalVersions[i].abi,
                                                                                "adjustVersionCode": true
                                                                            })
                                                                     break
                                                                 }
                                                             }
                                                         }
                                                     }
                                                     if (extraVersionName != null) {
                                                         append({
                                                                    "name": extraVersionName,
                                                                    "versionType": ProfileInfo.LOCKED_NAME
                                                                })
                                                     }
                                                 }

                            ListModel {
                                id: versionsmodel
                            }

                            function contains(arr, el) {
                                for (var i = 0; i < arr.length; ++i) {
                                    if (arr[i] === el) {
                                        return true
                                    }
                                }
                                return false
                            }

                            function excludeInstalledVersions(arr) {
                                var ret = []
                                var installed = {}
                                for (var i = 0; i < versions.length; i++)
                                    installed[versions[i].versionName] = versions[i].archs
                                for (i = 0; i < arr.length; i++) {
                                    // Show Beta in versionslist if in Beta program and allow showUnsupported or allow Beta
                                    if (arr[i].versionName in installed && contains(installed[arr[i].versionName], arr[i].abi) || arr[i].isBeta && (!playVerChannel.latestVersionIsBeta || !(launcherSettings.showUnsupported || launcherSettings.showBetaVersions)))
                                        continue
                                    ret.push(arr[i])
                                }
                                return ret
                            }
                        }
                    }
                }

                HorizontalDivider {
                    Layout.topMargin: 10
                    visible: advancedColumn.visible
                }

                ColumnLayout {
                    id: advancedColumn
                    visible: false
                    Layout.fillWidth: true
                    spacing: 5

                    MCheckBox {
                        id: dataDirCheck
                        Layout.topMargin: 10
                        text: qsTr("Data directory")
                        font.pointSize: parent.labelFontSize
                        font.bold: true
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        MTextField {
                            id: dataDirPath
                            enabled: dataDirCheck.checked
                            Layout.fillWidth: true
                        }
                        MButton {
                            enabled: dataDirCheck.checked
                            Layout.preferredHeight: dataDirPath.height
                            Layout.minimumWidth: 40
                            onClicked: {
                                if (dataDirPath.text !== null && dataDirPath.text.length > 0)
                                    dataDirPathDialog.folder = QmlUrlUtils.localFileToUrl(dataDirPath.text)
                                dataDirPathDialog.open()
                            }
                            Image {
                                anchors.centerIn: parent
                                width: 20
                                height: 20
                                source: "qrc:/Resources/icon-folder.png"
                                smooth: false
                            }
                        }
                        FolderDialog {
                            id: dataDirPathDialog
                            onAccepted: {
                                dataDirPath.text = QmlUrlUtils.urlToLocalFile(dataDirPathDialog.folder)
                            }
                        }
                    }

                    RowLayout {
                        spacing: 15
                        Layout.topMargin: 10
                        Layout.fillWidth: true

                        ColumnLayout {
                            Layout.fillWidth: true
                            MText {
                                text: qsTr("Texture Patch")
                                font.bold: true
                            }
                            MComboBox {
                                id: profileTexturePatch
                                Layout.fillWidth: true
                                textRole: "name"
                                ListModel {
                                    id: texturePatchModel
                                    ListElement {
                                        name: "Auto"
                                    }
                                    ListElement {
                                        name: "Enable"
                                    }
                                    ListElement {
                                        name: "Disable"
                                    }
                                }
                                model: texturePatchModel
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: SHOW_ANGLEBACKEND
                            MText {
                                text: "ANGLE backend"
                                font.bold: true
                            }
                            MComboBox {
                                id: profileGraphicsAPI
                                Layout.fillWidth: true
                                textRole: "name"
                                model: graphicsAPIModel
                                ListModel {
                                    id: graphicsAPIModel
                                    ListElement {
                                        name: "Default"
                                    }
                                    ListElement {
                                        name: "Metal"
                                    }
                                    ListElement {
                                        name: "OpenGL"
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            MCheckBox {
                                id: windowSizeCheck
                                text: qsTr("Window size")
                                font.bold: true
                                font.pointSize: parent.labelFontSize
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                MTextField {
                                    id: windowWidth
                                    enabled: windowSizeCheck.checked
                                    Layout.fillWidth: true
                                    validator: IntValidator {
                                        bottom: 0
                                        top: 3840
                                    }
                                }
                                MText {
                                    text: "x"
                                    font.pointSize: 11
                                    opacity: windowSizeCheck.checked ? 1.0 : 0.3
                                }
                                MTextField {
                                    id: windowHeight
                                    enabled: windowSizeCheck.checked
                                    Layout.fillWidth: true
                                    validator: IntValidator {
                                        bottom: 0
                                        top: 2160
                                    }
                                }
                            }
                        }
                    }

                    MText {
                        text: qsTr("Commandline")
                        Layout.topMargin: 10
                        font.bold: true
                    }
                    MTextField {
                        id: commandline
                        Layout.fillWidth: true
                    }

                    MText {
                        text: qsTr("Environment Variables")
                        font.bold: true
                        Layout.topMargin: 10
                        verticalAlignment: Text.AlignTop
                    }
                    Rectangle {
                        color: "#222"
                        Layout.preferredHeight: 120
                        Layout.fillWidth: true
                        ListView {
                            id: envs
                            clip: true
                            anchors.fill: parent
                            flickableDirection: Flickable.VerticalFlick
                            model: ListModel {}
                            Component.onCompleted: {
                                envs.model.append({
                                                      "key": "",
                                                      "value": "",
                                                      "add": true
                                                  })
                            }
                            delegate: Rectangle {
                                color: "#222"
                                width: parent.width
                                height: keyField.implicitHeight
                                MTextField {
                                    id: keyField
                                    visible: !add
                                    text: key
                                    width: (parent.width - del.implicitWidth) / 2
                                    anchors.left: parent.left
                                    placeholderText: "KEY"
                                    onEditingFinished: {
                                        envs.model.set(index, {
                                                           "key": text,
                                                           "value": value
                                                       })
                                    }
                                }
                                MTextField {
                                    visible: !add
                                    text: value
                                    anchors.left: keyField.right
                                    anchors.right: del.left
                                    placeholderText: "VALUE"
                                    onEditingFinished: {
                                        envs.model.set(index, {
                                                           "key": key,
                                                           "value": text
                                                       })
                                    }
                                }
                                MButton {
                                    visible: !add
                                    id: del
                                    height: parent.height
                                    anchors.right: parent.right
                                    Image {
                                        height: 20
                                        width: 20
                                        anchors.centerIn: parent
                                        source: "qrc:/Resources/icon-delete.png"
                                        smooth: false
                                    }
                                    onClicked: {
                                        console.log(index)
                                        envs.model.remove(index, 1)
                                    }
                                }
                                MButton {
                                    visible: !!add
                                    width: parent.width
                                    text: qsTr("Add New Variable")
                                    onClicked: {
                                        console.log(index)
                                        envs.model.insert(envs.model.count - 1, {
                                                              "key": "",
                                                              "value": ""
                                                          })
                                    }
                                }
                            }
                            highlightResizeVelocity: -1
                            highlightMoveVelocity: -1
                            currentIndex: -1
                            ScrollBar.vertical: ScrollBar {}
                        }
                    }
                }

                RowLayout {
                    id: buttons
                    Layout.topMargin: 15
                    TransparentButton {
                        Layout.alignment: Qt.AlignVCenter
                        text: advancedColumn.visible ? qsTr("Collapse advanced  🞁") : qsTr("Expand advanced  🞃")
                        textColor: hovered ? "#ccc" : "#888"
                        font.bold: true
                        onClicked: {
                            advancedColumn.visible = !advancedColumn.visible
                            advancedColumn.Layout.preferredHeight = advancedColumn.height
                        }
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    RowLayout {
                        spacing: 10
                        MButton {
                            text: qsTr("Cancel")
                            onClicked: close()
                        }
                        MButton {
                            text: qsTr("Save As")
                            enabled: profileName.text.length > 0 && profileName.text !== profile.name
                            visible: profile !== null && profileName.enabled
                            onClicked: {
                                saveProfile(true)
                                close()
                            }
                        }
                        MButton {
                            text: qsTr("Save")
                            enabled: !profileName.enabled || profileName.text.length > 0
                            onClicked: {
                                saveProfile()
                                close()
                            }
                        }
                    }
                }
            }
        }
    }

    function reset() {
        profile = null
        profileName.text = ""
        profileName.enabled = true
        profileVersion.extraVersionName = null
        profileVersion.update()
        profileVersion.currentIndex = 0
        profileTexturePatch.currentIndex = 0
        if (SHOW_ANGLEBACKEND) {
            profileGraphicsAPI.currentIndex = 0
        }
        dataDirCheck.checked = false
        dataDirPath.text = QmlUrlUtils.urlToLocalFile(launcherSettings.gameDataDir)
        windowSizeCheck.checked = false
        windowWidth.text = "720"
        windowHeight.text = "480"
        if (envs.model.count > 1) {
            envs.model.remove(0, envs.model.count - 1)
        }
        commandline.text = ""
    }

    function setProfile(p) {
        profile = p
        profileName.text = profile.name
        profileName.enabled = !profile.nameLocked
        profileVersion.extraVersionName = null
        profileVersion.update()
        if (profile.versionType == ProfileInfo.LATEST_GOOGLE_PLAY) {
            profileVersion.currentIndex = 0
        } else if (profile.versionType == ProfileInfo.LOCKED_CODE) {
            var index = -1
            for (var i = 0; i < versionsmodel.count; i++) {
                var entry = profileVersion.data[i]
                var diff = googleLoginHelperInstance.chromeOS ? 1000000000 : 0
                if (entry && entry.obj && ((entry.obj.versionCode === profile.versionCode) || (entry.obj.versionCode === (profile.versionCode - diff))) && profile.arch === entry.arch) {
                    index = i
                    break
                }
            }
            if (index === -1) {
                profileVersion.extraVersionName = getDisplayedVersionName()
                var extraversion = {
                    "name": profileVersion.extraVersionName,
                    "versionType": ProfileInfo.LOCKED_CODE,
                    "obj": {
                        "versionCode": profile.versionCode
                    },
                    "arch": profile.arch
                }
                versionsmodel.append(extraversion)
                profileVersion.data.push(extraversion)
                profileVersion.currentIndex = versionsmodel.count - 1
            } else {
                profileVersion.currentIndex = index
            }
        } else if (profile.versionType == ProfileInfo.LOCKED_NAME) {
            var index = -1
            for (var i = 0; i < versionsmodel.count; i++) {
                if (profileVersion.data[i].obj && profileVersion.data[i].obj.directory === profile.directory) {
                    index = i
                    break
                }
            }
            if (index === -1) {
                profileVersion.extraVersionName = getDisplayedVersionName() //profile.versionDirName
                var extraversion = {
                    "name": profileVersion.extraVersionName,
                    "versionType": ProfileInfo.LOCKED_NAME
                }
                versionsmodel.append(extraversion)
                profileVersion.data.push(extraversion)
                profileVersion.currentIndex = versionsmodel.count - 1
            } else {
                profileVersion.currentIndex = index
            }
        }

        profileTexturePatch.currentIndex = 0
        if (profile.texturePatch) {
            profileTexturePatch.currentIndex = profile.texturePatch
        }
        if (SHOW_ANGLEBACKEND) {
            profileGraphicsAPI.currentIndex = 0
            if (profile.graphicsAPI) {
                profileGraphicsAPI.currentIndex = profile.graphicsAPI
            }
        }

        dataDirCheck.checked = profile.dataDirCustom
        dataDirPath.text = profile.dataDir.length ? profile.dataDir : QmlUrlUtils.urlToLocalFile(launcherSettings.gameDataDir)
        windowSizeCheck.checked = profile.windowCustomSize
        windowWidth.text = profile.windowWidth
        windowHeight.text = profile.windowHeight
        if (envs.model.count > 1) {
            envs.model.remove(0, envs.model.count - 1)
        }
        var keys = profile.env.keys()
        for (var i = 0; i < keys.length; i++) {
            envs.model.insert(envs.model.count - 1, {
                                  "key": keys[i],
                                  "value": profile.env[keys[i]],
                                  "add": false
                              })
        }
        commandline.text = profile.commandline
    }

    function saveProfile(saveAs) {
        if (!profileManager.validateName(profileName.text)) {
            profileInvalidNameDialog.open()
            return
        }
        if (profile == null || (profile.name !== profileName.text && !profile.nameLocked)) {
            var profiles = profileManager.profiles
            for (var i = 0; i < profiles.length; i++) {
                if (profiles[i].name === profileName.text) {
                    profileNameConflictDialog.open()
                    return
                }
            }
            if (profile == null || saveAs)
                profile = profileManager.createProfile(profileName.text)
            else
                profile.setName(profileName.text)
        }
        profile.texturePatch = profileTexturePatch.currentIndex
        if (SHOW_ANGLEBACKEND) {
            profile.graphicsAPI = profileGraphicsAPI.currentIndex
        }
        profile.arch = ""
        var adjustVersionCode = false
        if (profileVersion.data[profileVersion.currentIndex].obj || profileVersion.data[profileVersion.currentIndex].versionType == ProfileInfo.LATEST_GOOGLE_PLAY) {
            profile.versionType = profileVersion.data[profileVersion.currentIndex].versionType
            // fails if it is a extraversion
            if (profile.versionType == ProfileInfo.LOCKED_NAME)
                profile.versionDirName = profileVersion.data[profileVersion.currentIndex].obj.directory
            if (profile.versionType == ProfileInfo.LOCKED_CODE) {
                profile.versionCode = profileVersion.data[profileVersion.currentIndex].obj.versionCode
                profile.arch = profileVersion.data[profileVersion.currentIndex].arch || ""
                adjustVersionCode = profileVersion.data[profileVersion.currentIndex].adjustVersionCode || false
            }
        }

        profile.windowCustomSize = windowSizeCheck.checked
        profile.dataDirCustom = dataDirCheck.checked
        profile.dataDir = dataDirPath.text
        profile.windowWidth = parseInt(windowWidth.text) || profile.windowWidth
        profile.windowHeight = parseInt(windowHeight.text) || profile.windowHeight
        profile.clearEnv()
        for (var i = 0; i < envs.model.count - 1; i++) {
            profile.env[envs.model.get(i).key] = envs.model.get(i).value
        }
        profile.commandline = commandline.text
        if (adjustVersionCode && googleLoginHelperInstance.chromeOS && (profile.versionCode > 982000000 && profile.versionCode < 990000000 || profile.versionCode > 972000000 && profile.versionCode < 980000000)) {
            profile.versionCode = profile.versionCode + 1000000000
        }
        profile.save()
    }

    MessageDialog {
        id: profileNameConflictDialog
        text: qsTr("A profile with the specified name already exists")
        title: qsTr("Profile Edit Error")
    }

    MessageDialog {
        id: profileInvalidNameDialog
        text: qsTr("The specified profile name is not valid")
        title: qsTr("Profile Edit Error")
    }
}
