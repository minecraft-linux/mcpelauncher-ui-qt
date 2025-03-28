import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Components"

ColumnLayout {
    width: parent.width
    spacing: 10
    id: settingsGeneralColumn
    property int labelFontSize: 10

    RowLayout {
        id: googleAcountRow
        property bool accountNotNull: googleLoginHelperInstance.account !== null

        ColumnLayout {
            MText {
                text: qsTr("Google Account")
                font.bold: true
            }
            Button {
                id: emailField
                property int wh: fontMetrics.advanceWidth(text)
                text: googleAcountRow.accountNotNull ? googleLoginHelperInstance.account.accountIdentifier : ""
                enabled: text
                hoverEnabled: true
                implicitWidth: wh + revealText.width + 10
                padding: 0
                contentItem: MText {
                    text: {
                        const mail = parent.text
                        if (emailField.pressed)
                            return mail
                        if (mail.length < 4)
                            return "..."
                        return mail.substring(0, 3) + "*".repeat(mail.length - 3)
                    }
                    MText {
                        id: revealText
                        x: emailField.wh + 10
                        text: qsTr("(Press to reveal)")
                        color: emailField.hovered ? "#aaa" : "#888"
                        visible: emailField.enabled
                    }
                }
                background: FocusBorder {
                    anchors.fill: parent
                    visible: parent.visualFocus
                }
                FontMetrics {
                    id: fontMetrics
                    font.pointSize: 10
                }
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

    MText {
        text: qsTr("Launcher")
        font.bold: true
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
        text: qsTr("Show all notification banners")
        Component.onCompleted: checked = launcherSettings.showNotifications
        onCheckedChanged: launcherSettings.showNotifications = checked
    }

    MCheckBox {
        text: qsTr("Show exit button in navigation bar")
        Component.onCompleted: checked = launcherSettings.showExitButton
        onCheckedChanged: launcherSettings.showExitButton = checked
    }

    MCheckBox {
        text: qsTr("ChromeOS Mode")
        Component.onCompleted: checked = launcherSettings.chromeOSMode
        onCheckedChanged: launcherSettings.chromeOSMode = checked
    }

    MCheckBox {
        text: qsTr("Trial Mode (implies ChromeOS Mode)")
        Component.onCompleted: checked = launcherSettings.trialMode
        onCheckedChanged: launcherSettings.trialMode = checked
    }

    MCheckBox {
        text: qsTr("Keep Apks in <GameData>/apks")
        Component.onCompleted: checked = launcherSettings.keepApks
        onCheckedChanged: launcherSettings.keepApks = checked
    }

    MButton {
        Layout.topMargin: 15
        text: qsTr("Run troubleshooter")
        onClicked: troubleshooterWindow.findIssuesAndShow()
    }

    MButton {
        text: qsTr("Open Gamepad Tool")
        onClicked: gamepadTool.show()
    }

    MButton {
        text: qsTr("Refresh Google Play Version Channel")
        onClicked: {
            var api = playVerChannel.playApi
            playVerChannel.playApi = null
            playVerChannel.playApi = api
        }
    }

    MButton {
        text: qsTr("Refresh Google Play Checkin")
        onClicked: {
            playVerChannel.playApi.cleanupLogin()
            var login = playVerChannel.playApi.login
            playVerChannel.playApi.login = null
            playVerChannel.playApi.login = login
        }
    }
}
