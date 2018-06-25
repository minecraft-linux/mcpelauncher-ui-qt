import QtQuick 2.4

import QtQuick.Controls 1.4
import QtQuick.Layouts 1.11
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.3
import QtQuick.Controls.Styles 1.4
import "ThemedControls"
import io.mrarm.mcpelauncher 1.0

Window {

    property VersionManager versionManager
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

            Text {
                anchors.fill: parent
                anchors.margins: { left: 20; right: 20 }
                color: "#ffffff"
                text: qsTr("Edit profile")
                font.pixelSize: 24
                verticalAlignment: Text.AlignVCenter
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

                id: profileVersion
                Layout.fillWidth: true
                model: {
                    var ret = []
                    ret.push("Latest version (Google Play)")
                    for (var i = 0; i < versions.length; i++)
                        ret.push(versions[i].versionName)
                    return ret
                }
            }

            Item {
                height: 8
                Layout.columnSpan: 2
            }

            MCheckBox {
                text: "Data directory"
                font.pointSize: parent.labelFontSize
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 2
                MTextField {
                    id: gameDirPath
                    Layout.fillWidth: true
                }
                MButton {
                    text: "..."
                    onClicked: {
                        gameDirPathDialog.open()
                    }
                }
                FileDialog {
                    id: gameDirPathDialog
                    selectFolder: true
                    onAccepted: {
                        gameDirPath.text = fileUrl
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
                    Layout.fillWidth: true
                    validator: IntValidator {
                        bottom: 0
                        top: 3840
                    }
                }
                Text {
                    text: "x"
                }
                MTextField {
                    id: windowHeight
                    Layout.fillWidth: true
                    validator: IntValidator {
                        bottom: 0
                        top: 2160
                    }
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
                }

                PlayButton {
                    Layout.preferredWidth: 150
                    text: "Cancel"
                }

            }

        }

    }


    function setProfile(p) {
        profile = p
        profileName.text = profile.name
        if (profile.versionType == ProfileInfo.LATEST_GOOGLE_PLAY)
            profileVersion.currentIndex = 0
        else
            profileVersion.currentIndex = 1 + profileVersion.versions.getByDirectory(profile.versionDirName)

        windowSizeCheck.checked = profile.windowCustomSize
        windowWidth.text = profile.windowWidth
        windowHeight.text = profile.windowHeight

    }

}
