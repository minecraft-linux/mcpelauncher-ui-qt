import QtQuick
import QtQuick.Window
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls
import "ThemedControls"

ScrollView {
    Layout.fillHeight: true
    Layout.fillWidth: true
    clip: true
    GridLayout {
        columns: 2
        columnSpacing: 20
        rowSpacing: 8
        id: gridLayout12
        property int labelFontSize: 12

        GampadTool {
            id: gamepadTool
        }

        Text {
            text: qsTr("Google Account")
            font.pointSize: parent.labelFontSize
        }
        Item {
            id: item1
            Layout.fillWidth: true
            height: childrenRect.height
            Layout.minimumWidth: googleAccountIdLabel.implicitWidth + googlesigninbtn.implicitWidth + 5

            RowLayout {
                anchors.right: parent.right
                Text {
                    text: googleLoginHelper.account !== null ? googleLoginHelper.account.accountIdentifier : ""
                    id: googleAccountIdLabel
                    Layout.alignment: Qt.AlignRight
                    font.pointSize: 11
                }
                MButton {
                    id: googlesigninbtn
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
            text: qsTr("Show log when starting the game")
            font.pointSize: parent.labelFontSize
            Layout.columnSpan: 2
            Component.onCompleted: checked = launcherSettings.startOpenLog
            onCheckedChanged: launcherSettings.startOpenLog = checked
        }

        MCheckBox {
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
            text: qsTr("Enable checking for updates (on opening)")
            font.pointSize: parent.labelFontSize
            Layout.columnSpan: 2
            Component.onCompleted: checked = launcherSettings.checkForUpdates
            onCheckedChanged: launcherSettings.checkForUpdates = checked
        }

        MCheckBox {
            text: qsTr("Show Notification banner")
            font.pointSize: parent.labelFontSize
            Layout.columnSpan: 2
            Component.onCompleted: checked = launcherSettings.showNotifications
            onCheckedChanged: launcherSettings.showNotifications = checked
        }

        MButton {
            Layout.topMargin: 20
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
            Layout.topMargin: 20
            text: qsTr("Open Gamepad Tool")
            Layout.columnSpan: 1
            onClicked: gamepadTool.show()
        }
        
    }
}
