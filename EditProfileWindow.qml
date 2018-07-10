import QtQuick 2.4

import QtQuick.Controls 1.4
import QtQuick.Layouts 1.2
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.3
import QtQuick.Controls.Styles 1.4
import "ThemedControls"
import io.mrarm.mcpelauncher 1.0

Window {

    property VersionManager versionManager
    property ProfileManager profileManager
    property ProfileInfo profile: null

    width: 500
    height: layout.implicitHeight
    flags: Qt.Dialog
    title: "Edit profile"

    ColumnLayout {
        id: layout
        anchors.fill: parent
        spacing: 20

        Image {
            id: title
            smooth: false
            fillMode: Image.Tile
            source: "Resources/noise.png"
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
                    text: "Delete profile"
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
            columnSpacing: 20
            rowSpacing: 8

            property int labelFontSize: 11

            Text {
                text: "Profile Name"
                font.pointSize: parent.labelFontSize
            }
            MTextField {
                id: profileName
                Layout.fillWidth: true
            }

            Text {
                text: "Version"
                font.pointSize: parent.labelFontSize
            }
            MComboBox {
                property var versions: versionManager.versions.getAll()
                property var extraVersionDirName: null

                id: profileVersion
                Layout.fillWidth: true
                model: {
                    var ret = []
                    ret.push("Latest version (Google Play)")
                    for (var i = 0; i < versions.length; i++)
                        ret.push(versions[i].versionName)
                    if (extraVersionDirName != null)
                        ret.push(extraVersionDirName)
                    return ret
                }
            }

            Item {
                height: 8
                Layout.columnSpan: 2
            }

            MCheckBox {
                id: dataDirCheck
                text: "Data directory"
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
                text: "Window size"
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
                MTextField {
                    id: pixelScale
                    enabled: windowSizeCheck.checked
                    Layout.preferredWidth: 50
                    validator: DoubleValidator {
                        bottom: 0
                        top: 16
                    }
                }
                Text {
                    text: "px scale"
                    font.pointSize: 11
                }
            }
        }

        Image {
            id: buttons
            smooth: false
            fillMode: Image.Tile
            source: "Resources/noise.png"
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            Layout.preferredHeight: 50

            RowLayout {
                x: parent.width / 2 - width / 2
                y: parent.height / 2 - height / 2

                spacing: 20

                PlayButton {
                    Layout.preferredWidth: 150
                    text: "Save"
                    onClicked: {
                        saveProfile()
                        close()
                    }
                }

                PlayButton {
                    Layout.preferredWidth: 150
                    text: "Cancel"
                    onClicked: close()
                }

            }

        }

    }

    function reset() {
        profile = null
        profileName.text = ""
        profileName.enabled = true
        profileVersion.currentIndex = 0
        dataDirCheck.checked = false
        dataDirPath.text = ""
        windowSizeCheck.checked = false
        windowWidth.text = "720"
        windowHeight.text = "480"
        pixelScale.text = "2"
    }

    function setProfile(p) {
        profile = p
        profileName.text = profile.name
        profileName.enabled = !profile.nameLocked
        if (profile.versionType == ProfileInfo.LATEST_GOOGLE_PLAY) {
            profileVersion.currentIndex = 0
        } else if (profile.versionType == ProfileInfo.LOCKED) {
            var index = -1
            for (var i = 0; i < profileVersion.versions.length; i++) {
                if (profileVersion.versions[i].directory === profile.versionDirName) {
                    index = i
                    break
                }
            }
            if (index === -1) {
                profileVersion.extraVersionDirName = profile.versionDirName
                profileVersion.currentIndex = profileVersion.versions.length + 1
            } else {
                profileVersion.currentIndex = index + 1
            }
        }

        dataDirCheck.checked = profile.dataDirCustom
        dataDirPath.text = profile.dataDir
        windowSizeCheck.checked = profile.windowCustomSize
        windowWidth.text = profile.windowWidth
        windowHeight.text = profile.windowHeight
        pixelScale.text = profile.pixelScale
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
        if (profileVersion.currentIndex == 0) {
            profile.versionType = ProfileInfo.LATEST_GOOGLE_PLAY
        } else {
            profile.versionType = ProfileInfo.LOCKED
            profile.versionDirName = profileVersion.versions[profileVersion.currentIndex - 1].directory
        }

        profile.windowCustomSize = windowSizeCheck.checked
        profile.dataDirCustom = dataDirCheck.checked
        profile.dataDir = dataDirPath.text
        profile.windowWidth = parseInt(windowWidth.text) || profile.windowWidth
        profile.windowHeight = parseInt(windowHeight.text) || profile.windowHeight
        profile.pixelScale = parseFloat(pixelScale.text) || profile.pixelScale
        profile.save()
    }

    MessageDialog {
        id: profileNameConflictDialog
        text: "A profile with the specified name already exists"
        title: "Profile Edit Error"
    }

    MessageDialog {
        id: profileInvalidNameDialog
        text: "The specified profile name is not valid"
        title: "Profile Edit Error"
    }

}
