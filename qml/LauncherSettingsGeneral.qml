import QtQuick 2.0

import QtQuick.Layouts 1.2
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

    MButton {
        Layout.topMargin: 20
        id: runTroubleshooter
        text: "Run troubleshooter"
        Layout.columnSpan: 2
        onClicked: troubleshooterWindow.findIssuesAndShow()
    }
}
