import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.2
import QtQuick.Controls 2.2
import "ThemedControls"

GridLayout {
    columns: 2
    columnSpacing: 20
    rowSpacing: 8

    property int labelFontSize: 12

    Text {
        text: qsTr("Google Account")
        font.pointSize: parent.labelFontSize
    }
    Item {
        id: item1
        Layout.fillWidth: true
        height: childrenRect.height

        RowLayout {
            anchors.right: parent.right
            spacing: 20
            Text {
                text: googleLoginHelper.account !== null ? googleLoginHelper.account.accountIdentifier : ""
                id: googleAccountIdLabel
                Layout.alignment: Qt.AlignRight
                font.pointSize: 11
            }
            MButton {
                Layout.alignment: Qt.AlignRight
                Layout.rightMargin: 20
                text: googleLoginHelper.account !== null ? qsTr("Sign out") : qsTr("Sign in")
                onClicked: {
                    if (googleLoginHelper.account !== null)
                        googleLoginHelper.signOut()
                    else
                        googleLoginHelper.acquireAccount(window)
                }
            }
        }
    }

    MCheckBox {
        Layout.topMargin: 20
        id: autoShowGameLog
        text: qsTr("Show log when starting the game")
        font.pointSize: parent.labelFontSize
        Layout.columnSpan: 2
        Component.onCompleted: checked = launcherSettings.startOpenLog
        onCheckedChanged: launcherSettings.startOpenLog = checked
    }

    MCheckBox {
        id: hideLauncher
        text: qsTr("Hide the launcher when starting the game")
        font.pointSize: parent.labelFontSize
        Layout.columnSpan: 2
        Component.onCompleted: checked = launcherSettings.startHideLauncher
        onCheckedChanged: launcherSettings.startHideLauncher = checked
    }

    MCheckBox {
        id: disableGameLog
        text: qsTr("Disable the GameLog")
        font.pointSize: parent.labelFontSize
        Layout.columnSpan: 2
        Component.onCompleted: checked = launcherSettings.disableGameLog
        onCheckedChanged: launcherSettings.disableGameLog = checked
    }

    MCheckBox {
        id: checkForUpdates
        text: qsTr("Enable checking for updates (startup)")
        font.pointSize: parent.labelFontSize
        Layout.columnSpan: 2
        Component.onCompleted: checked = launcherSettings.checkForUpdates
        onCheckedChanged: launcherSettings.checkForUpdates = checked
    }

    MCheckBox {
        text: qsTr("Show incompatible versions")
        font.pointSize: parent.labelFontSize
        Layout.columnSpan: 2
        Component.onCompleted: checked = launcherSettings.showUnsupported
        onCheckedChanged: launcherSettings.showUnsupported = checked
    }

    MCheckBox {
        text: qsTr("Show Beta Versions")
        font.pointSize: parent.labelFontSize
        Layout.columnSpan: 2
        Component.onCompleted: checked = launcherSettings.showBetaVersions
        onCheckedChanged: launcherSettings.showBetaVersions = checked
        enabled: playVerChannel.latestVersionIsBeta
    }

    MButton {
        Layout.topMargin: 20
        id: runTroubleshooter
        text: qsTr("Run troubleshooter")
        Layout.columnSpan: 1
        onClicked: troubleshooterWindow.findIssuesAndShow()
    }

    MButton {
        Layout.topMargin: 20
        text: qsTr("Open GameData Folder")
        Layout.columnSpan: 1
        onClicked: Qt.openUrlExternally(launcherSettings.gameDataDir)
    }

    MButton {
        text: qsTr("Check for Updates")
        Layout.columnSpan: 1
        onClicked: updateChecker.checkForUpdates()
    }

    MButton {
        text: qsTr("Reset Launcher Settings")
        Layout.columnSpan: 1
        onClicked: {
            launcherSettings.resetSettings()
            launcherreset.open()
        }
    }

    MessageDialog {
        id: launcherreset
        title: "Settings cleared"
        text: qsTr("Please reopen the Launcher to see the changes")
    }

    property var updateUrl: "";

    Connections {
        target: updateChecker
        onUpdateError: function(error) {
            if(window.active) {
                updateError.text = error
                updateError.open()
            }
        }
        onUpdateAvailable: function(url) {
            updateUrl = url;
        }
        onUpdateCheck: function(available) {
            if(window.active) {
                if(available) {
                    updateInfo.text = qsTr("An Update of the Launcher is available for download") + "<br/>" + (updateUrl.length !== 0 ? qsTr("You can download the new Update here: %1").arg(updateUrl) + "<br/>" : "") + qsTr("Do you want to update now?");
                    updateInfo.standardButtons = StandardButton.Yes | StandardButton.No
                } else {
                    updateInfo.standardButtons = StandardButton.Ok
                    updateInfo.text = qsTr("Your installed Launcher Version %1 (build %2) seems uptodate").arg(LAUNCHER_VERSION_NAME).arg(LAUNCHER_VERSION_CODE)
                }
                updateInfo.open()
            }
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
            if (updateUrl.length !== 0) {
                Qt.openUrlExternally(updateUrl)
            } else {
                updateChecker.startUpdate()
            }
        }
    }
}
