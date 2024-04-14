import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import Qt.labs.platform
import "ThemedControls"

ColumnLayout {
    id: columnlayout
    width: parent.width
    spacing: 10

    Text {
        text: qsTr("This project allows you to launch Minecraft: Bedrock Edition (as in the edition w/o the Edition suffix, previously known as Minecraft: Pocket Edition). The launcher supports Linux and OS X.<br/><br/>Version %1 (build %2)<br/> © Copyright 2018-2022, MrARM & contributors").arg(LAUNCHER_VERSION_NAME || "Unknown").arg(LAUNCHER_VERSION_CODE || "Unknown")
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
                updateInfo.text = qsTr("Your installed Launcher Version %1 (build %2) seems uptodate").arg(LAUNCHER_VERSION_NAME || '').arg(LAUNCHER_VERSION_CODE)
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
