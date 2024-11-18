import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "ThemedControls"
import io.mrarm.mcpelauncher 1.0

LauncherBase {
    signal finished
    id: unlockLayout
    spacing: 0

    headerContent: TabBar {
        background: null
        MTabButton {
            text: qsTr("Unlock Credentials")
            focusPolicy: Qt.NoFocus
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.margins: 20

        MText {
            Layout.fillWidth: true
            text: qsTr("This is not your Google Account Password. If you don't want to type it every time you open this Launcher, check \"Continue with invalid credentials\", then open Settings, press logout and finally login without providing your own encryption password.")
            wrapMode: Text.Wrap
            color: "white"
        }

        MCheckBox {
            id: continueInvalidCredentials
            Layout.topMargin: 10
            text: qsTr("Continue with invalid credentials")
            focus: true
        }

        Item {
            Layout.fillHeight: true
        }

        Rectangle {
            id: warning
            opacity: 0
            color: "#30ff8000"
            Layout.fillWidth: true
            Layout.bottomMargin: 15
            Layout.minimumHeight: warningText.height
            radius: 4
            MText {
                id: warningText
                padding: 10
                text: qsTr("Password is invalid")
                wrapMode: Text.WordWrap
                width: parent.width
            }

            OpacityAnimator {
                id: warningAnim
                target: warning
                from: 1
                to: 0
                duration: 1000
                running: false
                easing.type: Easing.InExpo
            }
        }

        MText {
            text: "Password"
            font.bold: true
        }

        MTextField {
            id: pwd
            Layout.fillWidth: true
            echoMode: TextInput.Password
            enabled: !continueInvalidCredentials.checked
            onAccepted: attemptUnlock()
            onTextChanged: {
                pwd.color = "#fff"
            }
            NumberAnimation on x {
                id: shakeAnim
                from: 3
                to: -3
                duration: 110
                loops: 2
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.minimumHeight: pbutton.height + 10 * 2
        color: "#242424"
        MButton {
            id: pbutton
            text: qsTr("Continue")
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 10
            onClicked: attemptUnlock()
        }
    }

    function attemptUnlock() {
        googleLoginHelperInstance.unlockkey = pwd.text
        if (googleLoginHelperInstance.account && !googleLoginHelperInstance.hasEncryptedCredentials || continueInvalidCredentials.checked) {
            unlockLayout.finished()
        } else {
            warning.opacity = 1
            warningAnim.restart()
            shakeAnim.restart()
            pwd.color = "#f88"
            pwd.forceActiveFocus()
        }
    }
}
