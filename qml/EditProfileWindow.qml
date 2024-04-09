import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Dialogs
import QtQuick.Controls
import Qt.labs.platform
import "ThemedControls"
import io.mrarm.mcpelauncher 1.0

Window {
    property VersionManager versionManager
    property ProfileManager profileManager
    property GoogleVersionChannel playVerChannel
    property ProfileInfo profile: null

    id: editProfileWindow
    width: 500
    height: layout.implicitHeight
    minimumWidth: 500
    minimumHeight: layout.implicitHeight
    flags: Qt.Dialog
    title: qsTr("Edit profile")
    color: "#333333"

    ColumnLayout {
        id: layout
        anchors.fill: parent
        spacing: 20
        BaseHeader {
            title: editProfileWindow.title
            MButton {
                text: qsTr("Delete profile")
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

        GridLayout {
            columns: 2
            Layout.fillWidth: true
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            Layout.alignment: Qt.AlignTop
            columnSpacing: 20
            rowSpacing: 8

            property int labelFontSize: 10

            Text {
                text: qsTr("Profile Name")
                color: "#fff"
                font.pointSize: parent.labelFontSize
            }
            MTextField {
                id: profileName
                Layout.fillWidth: true
            }

            Text {
                text: qsTr("Version")
                color: "#fff"
                font.pointSize: parent.labelFontSize
            }
            MComboBox {
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
                                                                    "arch": archivalVersions[i].abi
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
                color: "#fff"
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
                text: "ANGLE backend"
                color: "#fff"
                font.pointSize: parent.labelFontSize
            }

            MComboBox {
                visible: SHOW_ANGLEBACKEND
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
                    height: dataDirPath.height
                    onClicked: {
                        if (dataDirPath.text !== null && dataDirPath.text.length > 0)
                            dataDirPathDialog.folder = QmlUrlUtils.localFileToUrl(dataDirPath.text)
                        dataDirPathDialog.open()
                    }
                }
                FolderDialog {
                    id: dataDirPathDialog
                    onAccepted: {
                        dataDirPath.text = QmlUrlUtils.urlToLocalFile(dataDirPathDialog.folder)
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
                    color: "#fff"
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

        Item {
            Layout.fillHeight: true
        }

        Rectangle {
            id: buttons
            color: "#242424"
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            RowLayout {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 10
                spacing: 10
                MButton {
                    text: qsTr("Cancel")
                    onClicked: close()
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
                if (entry && entry.obj && entry.obj.versionCode === profile.versionCode && profile.arch === entry.arch) {
                    index = i
                    break
                }
            }
            if (index === -1) {
                profileVersion.extraVersionName = getDisplayedVersionName()
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
        if (profileVersion.data[profileVersion.currentIndex].obj || profileVersion.data[profileVersion.currentIndex].versionType == ProfileInfo.LATEST_GOOGLE_PLAY) {
            profile.versionType = profileVersion.data[profileVersion.currentIndex].versionType
            // fails if it is a extraversion
            if (profile.versionType == ProfileInfo.LOCKED_NAME)
                profile.versionDirName = profileVersion.data[profileVersion.currentIndex].obj.directory
            if (profile.versionType == ProfileInfo.LOCKED_CODE) {
                profile.versionCode = profileVersion.data[profileVersion.currentIndex].obj.versionCode
                profile.arch = profileVersion.data[profileVersion.currentIndex].arch || ""
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
