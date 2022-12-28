import QtQuick 2.9

import QtQuick.Layouts 1.2
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2
import "ThemedControls"

ColumnLayout {
    id: columnlayout
    Layout.fillWidth: true
    
    TextEdit {
        textFormat: TextEdit.RichText
        text: qsTr("This project allows you to launch Minecraft: Bedrock Edition (as in the edition w/o the Edition suffix, previously known as Minecraft: Pocket Edition). The launcher supports Linux and OS X.<br/><br/>Version %1 (build %2)<br/> © Copyright 2018-2022, MrARM & contributors").arg(LAUNCHER_VERSION_NAME || "Unknown").arg(LAUNCHER_VERSION_CODE || "Unknown")
        readOnly: true
        wrapMode: Text.WordWrap
        selectByMouse: true
        Layout.fillWidth: true
    }

    ColumnLayout {
        Layout.fillWidth: true
        MButton {
            Layout.fillWidth: true
            text: qsTr("Check for Updates")
            Layout.columnSpan: 1
            onClicked: {
                updateCheckerConnectorSettings.enabled = true
                updateChecker.checkForUpdates()
            }
        }

        MButton {
            Layout.fillWidth: true
            text: qsTr("Reset Launcher Settings")
            Layout.columnSpan: 1
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

    property var updateUrl: "";

    Connections {
        id: updateCheckerConnectorSettings
        target: updateChecker
        enabled: false
        onUpdateError: function(error) {
            updateCheckerConnectorSettings.enabled = false
            updateError.text = error
            updateError.open()
        }
        onUpdateAvailable: function(url) {
            columnlayout.updateUrl = url;
        }
        onUpdateCheck: function(available) {
            updateCheckerConnectorSettings.enabled = false
            if (available) {
                updateInfo.text = qsTr("An Update of the Launcher is available for download") + "<br/>" + (columnlayout.updateUrl.length !== 0 ? qsTr("You can download the new Update here: %1").arg(columnlayout.updateUrl) + "<br/>" : "") + qsTr("Do you want to update now?");
                updateInfo.standardButtons = StandardButton.Yes | StandardButton.No
            } else {
                updateInfo.standardButtons = StandardButton.Ok
                updateInfo.text = qsTr("Your installed Launcher Version %1 (build %2) seems uptodate").arg(LAUNCHER_VERSION_NAME || '').arg(LAUNCHER_VERSION_CODE)
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
        onYes: {
            if (columnlayout.updateUrl.length !== 0) {
                Qt.openUrlExternally(columnlayout.updateUrl)
            } else {
                updateCheckerConnectorSettings.enabled = true
                updateChecker.startUpdate()
            }
        }
    }

}
