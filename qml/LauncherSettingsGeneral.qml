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
        text: "Google Account"
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
                text: googleLoginHelper.account !== null ? "Sign out" : "Sign in"
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
        text: "Show log when starting the game"
        font.pointSize: parent.labelFontSize
        Layout.columnSpan: 2
        Component.onCompleted: checked = launcherSettings.startOpenLog
        onCheckedChanged: launcherSettings.startOpenLog = checked
    }

    MCheckBox {
        id: hideLauncher
        text: "Hide the launcher when starting the game"
        font.pointSize: parent.labelFontSize
        Layout.columnSpan: 2
        Component.onCompleted: checked = launcherSettings.startHideLauncher
        onCheckedChanged: launcherSettings.startHideLauncher = checked
    }

    MCheckBox {
        id: disableGameLog
        text: "Disable the GameLog"
        font.pointSize: parent.labelFontSize
        Layout.columnSpan: 2
        Component.onCompleted: checked = launcherSettings.disableGameLog
        onCheckedChanged: launcherSettings.disableGameLog = checked
    }

    MCheckBox {
        id: checkForUpdates
        text: "Enable checking for updates (startup)"
        font.pointSize: parent.labelFontSize
        Layout.columnSpan: 2
        Component.onCompleted: checked = launcherSettings.checkForUpdates
        onCheckedChanged: launcherSettings.checkForUpdates = checked
    }

    MCheckBox {
        text: "Show incompatible versions"
        font.pointSize: parent.labelFontSize
        Layout.columnSpan: 2
        Component.onCompleted: checked = launcherSettings.showUnsupported
        onCheckedChanged: launcherSettings.showUnsupported = checked
    }

    MCheckBox {
        text: "Show Beta Versions"
        font.pointSize: parent.labelFontSize
        Layout.columnSpan: 2
        Component.onCompleted: checked = launcherSettings.showBetaVersions
        onCheckedChanged: launcherSettings.showBetaVersions = checked
        enabled: playVerChannel.latestVersionIsBeta
    }

    MButton {
        Layout.topMargin: 20
        id: runTroubleshooter
        text: "Run troubleshooter"
        Layout.columnSpan: 1
        onClicked: troubleshooterWindow.findIssuesAndShow()
    }

    MButton {
        Layout.topMargin: 20
        text: "Open GameData Folder"
        Layout.columnSpan: 1
        onClicked: Qt.openUrlExternally(launcherSettings.gameDataDir)
    }

    MButton {
        text: "Check for Updates"
        Layout.columnSpan: 1
        onClicked: updateChecker.checkForUpdates()
    }

    MButton {
        text: "Reset Launcher Settings"
        Layout.columnSpan: 1
        onClicked: {
            launcherSettings.resetSettings()
            launcherreset.open()
        }
    }

    MessageDialog {
        id: launcherreset
        title: "Settings cleared"
        text: "Please reopen the Launcher to see the changes"
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
                    updateInfo.text = "An Update of the Launcher is available for download<br/>" + (updateUrl.length !== 0 ? "You can download the new Update here: " + updateUrl + "<br/>" : "") + "Do you want to update now?";
                    updateInfo.standardButtons = StandardButton.Yes | StandardButton.No
                } else {
                    updateInfo.standardButtons = StandardButton.Ok
                    updateInfo.text = "You installed Launcher Version " + LAUNCHER_VERSION_NAME + " (build " + LAUNCHER_VERSION_CODE + ") seems uptodate"
                }
                updateInfo.open()
            }
        }
    }

    MessageDialog {
        id: updateError
        title: "Update failed"
    }

    MessageDialog {
        id: updateInfo
        title: "Update Information"
        onYes: {
            if (updateUrl.length !== 0) {
                Qt.openUrlExternally(updateUrl)
            } else {
                updateChecker.startUpdate()
            }
        }
    }
}
