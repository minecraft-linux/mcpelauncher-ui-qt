import QtQuick
import QtQuick.Layouts
import "ThemedControls"

ColumnLayout {
    width: parent.width
    spacing: 10
    id: settingsGeneralColumn
    property int labelFontSize: 10

    RowLayout {
        id: googleAcountRow
        property bool accountNotNull: googleLoginHelperInstance.account !== null

        ColumnLayout {
            Text {
                text: qsTr("Google Account")
                color: "#fff"
                font.bold: true
                font.pointSize: settingsGeneralColumn.labelFontSize
            }
            Text {
                id: googleAccountIdLabel
                text: googleAcountRow.accountNotNull ? googleLoginHelperInstance.account.accountIdentifier : "..."
                color: "#fff"
                font.pointSize: settingsGeneralColumn.labelFontSize
            }
        }

        Item {
            Layout.fillWidth: true
        }

        MButton {
            id: googlesigninbtn
            Layout.alignment: Qt.AlignRight
            text: googleAcountRow.accountNotNull ? qsTr("Sign out") : qsTr("Sign in")
            onClicked: {
                if (googleAcountRow.accountNotNull)
                    googleLoginHelperInstance.signOut()
                else
                    googleLoginHelperInstance.acquireAccount(window)
            }
        }
    }

    HorizontalDivider {}

    Text {
        text: qsTr("Launcher")
        color: "#fff"
        font.bold: true
        font.pointSize: parent.labelFontSize
    }

    MCheckBox {
        text: qsTr("Show log when starting the game")
        Component.onCompleted: checked = launcherSettings.startOpenLog
        onCheckedChanged: launcherSettings.startOpenLog = checked
    }

    MCheckBox {
        text: qsTr("Hide the launcher when starting the game")
        Component.onCompleted: checked = launcherSettings.startHideLauncher
        onCheckedChanged: launcherSettings.startHideLauncher = checked
    }

    MCheckBox {
        id: disableGameLog
        text: qsTr("Disable the GameLog")
        Component.onCompleted: checked = launcherSettings.disableGameLog
        onCheckedChanged: launcherSettings.disableGameLog = checked
    }

    MCheckBox {
        text: qsTr("Enable checking for updates (on opening)")
        Component.onCompleted: checked = launcherSettings.checkForUpdates
        onCheckedChanged: launcherSettings.checkForUpdates = checked
    }

    MCheckBox {
        text: qsTr("Show Notification banner")
        Component.onCompleted: checked = launcherSettings.showNotifications
        onCheckedChanged: launcherSettings.showNotifications = checked
    }

    MButton {
        Layout.topMargin: 15
        text: qsTr("Run troubleshooter")
        onClicked: troubleshooterWindow.findIssuesAndShow()
    }

    MButton {
        text: qsTr("Open GameData Folder")
        onClicked: Qt.openUrlExternally(launcherSettings.gameDataDir)
    }

    MButton {
        text: qsTr("Open Gamepad Tool")
        onClicked: gamepadTool.show()
    }

    GampadTool {
        id: gamepadTool
    }
}
