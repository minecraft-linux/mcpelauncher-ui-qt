import QtQuick 2.4

import QtQuick.Layouts 1.2
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.2
import QtQuick.Controls.Styles 1.4
import "ThemedControls"
import io.mrarm.mcpelauncher 1.0

Window {

    property VersionManager versionManager
    property ProfileManager profileManager
    property GoogleVersionChannel playVerChannel
    property ProfileInfo profile: null

    width: 500
    height: layout.implicitHeight
    minimumWidth: 500
    minimumHeight: layout.implicitHeight
    flags: Qt.Dialog
    title: qsTr("Edit profile")

    ColumnLayout {
        id: layout
        anchors.fill: parent
        spacing: 20

        Image {
            id: title
            smooth: false
            fillMode: Image.Tile
            source: "qrc:/Resources/noise.png"
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            Layout.preferredHeight: 50

            RowLayout {
                anchors.fill: parent

                Text {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: 20
                    color: "#ffffff"
                    text: qsTr("Edit profile")
                    font.pixelSize: 24
                    verticalAlignment: Text.AlignVCenter
                }

                MButton {
                    text: qsTr("Delete profile")
                    Layout.rightMargin: 20
                    visible: profile !== null && profile !== profileManager.defaultProfile
                    onClicked: {
                        profileManager.deleteProfile(profile)
                        close()
                    }
                }

            }

        }

        GridLayout {
            columns: 2
            Layout.fillWidth: true
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            Layout.alignment: Qt.AlignTop
            columnSpacing: 20
            rowSpacing: 8

            property int labelFontSize: 11

            Text {
                text: qsTr("Profile Name")
                font.pointSize: parent.labelFontSize
            }
            MTextField {
                id: profileName
                Layout.fillWidth: true
            }

            Text {
                text: qsTr("Version")
                font.pointSize: parent.labelFontSize
            }
            MComboBox {
                property var versions: versionManager.versions.getAll().sort(function(a, b) { return b.versionCode - a.versionCode; })
                property var archivalVersions: excludeInstalledVersions(versionManager.archivalVersions.versions)
                property var extraVersionName: null
                property var hideLatest: googleLoginHelper.hideLatest
                property var update: function() {
                    versionsmodel.clear();
                    var abis = googleLoginHelper.getAbis(launcherSettings.showUnsupported)
                    if (!hideLatest && googleLoginHelper.account !== null && playVerChannel.hasVerifiedLicense) {
                        var support = checkGooglePlayLatestSupport()
                        var latest = support ? playVerChannel.latestVersion : launcherLatestVersion().versionName
                        versionsmodel.append({name: qsTr("Latest %1 (%2)").arg((latest.length === 0 ? qsTr("version") : latest)).arg((support ? qsTr("Google Play") : qsTr("compatible"))), versionType: ProfileInfo.LATEST_GOOGLE_PLAY})
                    }
                    for (var i = 0; i < versions.length; i++) {
                        for (var j = 0; j < abis.length; j++) {
                            for (var k = 0; k < versions[i].archs.length; k++) {
                                if (versions[i].archs[k] == abis[j]) {
                                    versionsmodel.append({name: qsTr("%1 (installed, %2)").arg(versions[i].versionName).arg(versions[i].archs[k]), versionType: ProfileInfo.LOCKED_CODE, obj: versions[i], arch: versions[i].archs[k] })
                                    break;
                                }
                            }
                        }
                    }
                    if (!hideLatest && googleLoginHelper.account !== null && playVerChannel.hasVerifiedLicense) {
                        for (i = 0; i < archivalVersions.length; i++) {
                            for (var j = 0; j < abis.length; j++) {
                                if (archivalVersions[i].abi == abis[j]) {
                                    versionsmodel.append({name: qsTr("%1 (%2%3)").arg(archivalVersions[i].versionName).arg(archivalVersions[i].abi).arg((archivalVersions[i].isBeta ? (qsTr(", ") + qsTr("beta")) : "")), versionType: ProfileInfo.LOCKED_CODE, obj: archivalVersions[i], arch: archivalVersions[i].abi})
                                    break;
                                }
                            }
                        }
                    }
                    if (extraVersionName != null) {
                        versionsmodel.append({name: extraVersionName, versionType: ProfileInfo.LOCKED_NAME})
                    }
                }
                
                ListModel {
                    id: versionsmodel
                }

                function contains(arr, el) {
                    for (var i = 0; i < arr.length; ++i) {
                        if (arr[i] === el) {
                            return true;
                        }
                    }
                    return false;
                }

                function excludeInstalledVersions(arr) {
                    var ret = []
                    var installed = {}
                    for (var i = 0; i < versions.length; i++)
                        installed[versions[i].versionName] = versions[i].archs
                    for (i = 0; i < arr.length; i++) {
                        // Show Beta in versionslist if in Beta program and allow showUnsupported or allow Beta
                        if (arr[i].versionName in installed && contains(installed[arr[i].versionName], arr[i].abi) || arr[i].isBeta && (!playVerChannel.latestVersionIsBeta || !(launcherSettings.showUnsupported || launcherSettings.showBetaVersions)))
                            continue;
                        ret.push(arr[i])
                    }
                    return ret
                }

                id: profileVersion
                Layout.fillWidth: true

                textRole: "name"
                model: versionsmodel
            }

            Item {
                height: 8
                Layout.columnSpan: 2
            }

            Text {
                text: qsTr("Texture Patch")
                font.pointSize: parent.labelFontSize
            }
            MComboBox {                
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


                id: profileTexturePatch
                Layout.fillWidth: true

                textRole: "name"
                model: texturePatchModel
            }
                Text {
                    visible: SHOW_ANGLEBACKEND
                    text: qsTr("ANGLE backend")
                    font.pointSize: parent.labelFontSize
                }

                MComboBox {
                    visible: SHOW_ANGLEBACKEND                
                    ListModel {
                        id: graphicsAPIModel
                        ListElement {
                            name: "Metal"
                        }
                        ListElement {
                            name: "OpenGL"
                        }
                    }


                    id: profileGraphicsAPI
                    Layout.fillWidth: true

                    textRole: "name"
                    model: graphicsAPIModel
                }
            MCheckBox {
                id: dataDirCheck
                text: qsTr("Data directory")
                font.pointSize: parent.labelFontSize
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
                    text: "..."
                    enabled: dataDirCheck.checked
                    onClicked: {
                        if (dataDirPath.text !== null && dataDirPath.text.length > 0)
                            dataDirPathDialog.folder = QmlUrlUtils.localFileToUrl(dataDirPath.text)
                        dataDirPathDialog.open()
                    }
                }
                FileDialog {
                    id: dataDirPathDialog
                    selectFolder: true
                    onAccepted: {
                        dataDirPath.text = QmlUrlUtils.urlToLocalFile(fileUrl)
                    }
                }
            }

            MCheckBox {
                id: windowSizeCheck
                text: qsTr("Window size")
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
                Text {
                    text: "x"
                    font.pointSize: 11
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
                Item {
                    Layout.preferredWidth: 10
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }

        Image {
            id: buttons
            smooth: false
            fillMode: Image.Tile
            source: "qrc:/Resources/noise.png"
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            Layout.preferredHeight: 50

            RowLayout {
                x: parent.width / 2 - width / 2
                y: parent.height / 2 - height / 2

                spacing: 20

                PlayButton {
                    Layout.preferredWidth: 150
                    text: qsTr("Save")
                    enabled: !profileName.enabled || profileName.text.length > 0
                    onClicked: {
                        saveProfile()
                        close()
                    }
                }

                PlayButton {
                    Layout.preferredWidth: 150
                    text: qsTr("Cancel")
                    onClicked: close()
                }

            }

        }

    }

    function reset() {
        profile = null
        profileName.text = ""
        profileName.enabled = true
        profileVersion.update();
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
    }

    function setProfile(p) {
        profile = p
        profileName.text = profile.name
        profileName.enabled = !profile.nameLocked
        profileVersion.update();
        if (profile.versionType == ProfileInfo.LATEST_GOOGLE_PLAY) {
            profileVersion.currentIndex = 0
        } else if (profile.versionType == ProfileInfo.LOCKED_CODE) {
            var index = -1
            for (var i = 0; i < versionsmodel.count; i++) {
                if (versionsmodel.get(i).obj && versionsmodel.get(i).obj.versionCode === profile.versionCode && profile.arch === versionsmodel.get(i).arch) {
                    index = i
                    break
                }
            }
            if (index === -1) {
                profileVersion.extraVersionName = getDisplayedVersionName();
                versionsmodel.append({name: profileVersion.extraVersionName, versionType: ProfileInfo.LOCKED_NAME})
                profileVersion.currentIndex = versionsmodel.count - 1
            } else {
                profileVersion.currentIndex = index
            }
        } else if (profile.versionType == ProfileInfo.LOCKED_NAME) {
            var index = -1
            for (var i = 0; i < versionsmodel.count; i++) {
                if (versionsmodel.get(i).obj && versionsmodel.get(i).obj.directory === profile.directory) {
                    index = i
                    break
                }
            }
            if (index === -1) {
                profileVersion.extraVersionName = getDisplayedVersionName()//profile.versionDirName
                versionsmodel.append({name: profileVersion.extraVersionName, versionType: ProfileInfo.LOCKED_NAME})
                profileVersion.currentIndex = versionsmodel.count - 1
            } else {
                profileVersion.currentIndex = index
            }
        }

        profileTexturePatch.currentIndex = 0;
        if(profile.texturePatch) {
            profileTexturePatch.currentIndex = profile.texturePatch;
        }
        if (SHOW_ANGLEBACKEND) {
            profileGraphicsAPI.currentIndex = 0;
            if(profile.graphicsAPI) {
                profileGraphicsAPI.currentIndex = profile.graphicsAPI;
            }
        }

        dataDirCheck.checked = profile.dataDirCustom
        dataDirPath.text = profile.dataDir.length ? profile.dataDir : QmlUrlUtils.urlToLocalFile(launcherSettings.gameDataDir)
        windowSizeCheck.checked = profile.windowCustomSize
        windowWidth.text = profile.windowWidth
        windowHeight.text = profile.windowHeight
    }

    function saveProfile() {
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
            if (profile == null)
                profile = profileManager.createProfile(profileName.text)
            else
                profile.setName(profileName.text)
        }
        profile.texturePatch = profileTexturePatch.currentIndex
        if (SHOW_ANGLEBACKEND) {
            profile.graphicsAPI = profileGraphicsAPI.currentIndex
        }
        profile.arch = ""
        if (versionsmodel.get(profileVersion.currentIndex).obj || versionsmodel.get(profileVersion.currentIndex).versionType == ProfileInfo.LATEST_GOOGLE_PLAY) {
            profile.versionType = versionsmodel.get(profileVersion.currentIndex).versionType
            // fails if it is a extraversion
            if (profile.versionType == ProfileInfo.LOCKED_NAME)
                profile.versionDirName = versionsmodel.get(profileVersion.currentIndex).obj.directory
            if (profile.versionType == ProfileInfo.LOCKED_CODE) {
                profile.versionCode = versionsmodel.get(profileVersion.currentIndex).obj.versionCode
                profile.arch = versionsmodel.get(profileVersion.currentIndex).arch || ""
            }
        }

        profile.windowCustomSize = windowSizeCheck.checked
        profile.dataDirCustom = dataDirCheck.checked
        profile.dataDir = dataDirPath.text
        profile.windowWidth = parseInt(windowWidth.text) || profile.windowWidth
        profile.windowHeight = parseInt(windowHeight.text) || profile.windowHeight
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
