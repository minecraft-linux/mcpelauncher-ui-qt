import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import Qt.labs.platform
import "ThemedControls"

ColumnLayout {
    id: columnlayout
    width: parent.width
    spacing: 10

    Image {
        Layout.preferredHeight: 80
        Layout.preferredWidth: 80
        Layout.alignment: Qt.AlignHCenter
        source: "qrc:/Resources/mcpelauncher-icon.svg"
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        font.pointSize: 12
        font.bold: true
        color: "#fff"
        text: qsTr("Launcher")
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        horizontalAlignment: Text.AlignHCenter
        Layout.bottomMargin: 10
        font.pointSize: 10
        color: "#fff"
        text: qsTr("Version: %1<br/>Build: %2").arg(LAUNCHER_VERSION_NAME || "Unknown").arg((LAUNCHER_VERSION_CODE || "Unknown").toString())
    }

    Flow {
        Layout.bottomMargin: 10
        Layout.alignment: Qt.AlignHCenter
        spacing: 25
        Repeater {
            model: [{
                    "label": qsTr("Source"),
                    "link": "https://github.com/minecraft-linux/mcpelauncher-manifest"
                }, {
                    "label": qsTr("Discord"),
                    "link": "https://discord.gg/TaUNBXr"
                }, {
                    "label": qsTr("Docs"),
                    "link": "https://minecraft-linux.github.io"
                }]
            delegate: Text {
                font.pointSize: 10
                textFormat: Text.RichText
                text: "<a href='%1' style='color:#b9f;text-decoration:none;'>&#129125;&nbsp;%2</a>".arg(modelData.link).arg(modelData.label)
                onLinkActivated: Qt.openUrlExternally(link)
                opacity: hoveredLink ? 0.8 : 1.0
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                }
            }
        }
    }

    HorizontalDivider {}

    Text {
        text: qsTr("This project allows you to launch Minecraft: Bedrock Edition (as in the edition w/o the Edition suffix, previously known as Minecraft: Pocket Edition). The launcher supports Linux and OS X.<br/><br/> © Copyright 2018-2024, MrARM & contributors")
        color: "#fff"
        wrapMode: Text.WordWrap
        font.pointSize: 10
        Layout.fillWidth: true
    }

    HorizontalDivider {}

    RowLayout {
        MButton {
            text: qsTr("Check for Updates")
            onClicked: {
                updateCheckerConnectorSettings.enabled = true
                updateChecker.checkForUpdates()
            }
        }
        Item {
            Layout.fillWidth: true
        }
        MButton {
            text: qsTr("Reset Launcher Settings")
            onClicked: {
                launcherSettings.resetSettings()
                launcherreset.open()
            }
        }
    }

    MessageDialog {
        id: launcherreset
        title: "Settings cleared"
        text: qsTr("Please reopen the Launcher to see the changes")
    }

    property string updateUrl: ""

    Connections {
        id: updateCheckerConnectorSettings
        target: updateChecker
        enabled: false
        onUpdateError: function (error) {
            updateCheckerConnectorSettings.enabled = false
            updateError.text = error
            updateError.open()
        }
        onUpdateAvailable: function (url) {
            columnlayout.updateUrl = url
        }
        onUpdateCheck: function (available) {
            updateCheckerConnectorSettings.enabled = false
            if (available) {
                updateInfo.text = qsTr("An Update of the Launcher is available for download") + "<br/>" + (columnlayout.updateUrl.length !== 0 ? qsTr("You can download the new Update here: %1").arg(columnlayout.updateUrl) + "<br/>" : "") + qsTr("Do you want to update now?")
                updateInfo.buttons = MessageDialog.Yes | MessageDialog.No
            } else {
                updateInfo.text = qsTr("Your installed Launcher Version %1 (build %2) seems uptodate").arg(LAUNCHER_VERSION_NAME || '').arg(LAUNCHER_VERSION_CODE.toString())
                updateInfo.buttons = MessageDialog.Ok
            }
            updateInfo.open()
        }
    }

    MessageDialog {
        id: updateError
        title: qsTr("Update failed")
    }

    MessageDialog {
        id: updateInfo
        title: qsTr("Update Information")
        onYesClicked: {
            if (columnlayout.updateUrl.length !== 0) {
                Qt.openUrlExternally(columnlayout.updateUrl)
            } else {
                updateCheckerConnectorSettings.enabled = true
                updateChecker.startUpdate()
            }
        }
    }
}
