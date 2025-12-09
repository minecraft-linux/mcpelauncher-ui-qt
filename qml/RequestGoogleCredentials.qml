import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.2
import QtQuick.Controls 2.1
import io.mrarm.mcpelauncher 1.0

Window {
    id: window
    visible: true
    width: 640
    height: 480
    title: qsTr("Request Google Credentials")
    color: "#333333"
    property bool hasUpdate: false
    property bool hasAskedForKey: false
    property string updateDownloadUrl: ""
    property bool isVersionsInitialized: false
    property string currentGameDataDir: ""

    StackView {
        id: stackView
        anchors.fill: parent
    }

    GoogleLoginHelper {
        id: googleLoginHelperInstance
        includeIncompatible: launcherSettings.showUnsupported
        singleArch: launcherSettings.singleArch
        chromeOS: launcherSettings.chromeOSMode || launcherSettings.trialMode
    }

    Component {
        id: panelError
        ErrorScreen {
            onFinished: defaultnext()
        }
    }

    StdioHelper {
        id: stdio
    }

    Component {
        id: panelDefault
        ErrorScreen {
            message: qsTr("A mod at '%1'<br/>is requesting access to your google credentials,<br/>to reject this request close this window").arg(SOURCE_MOD)
            onFinished: {
                stdio.error("CRED=" + googleLoginHelperInstance.account.accountIdentifier + ":" + googleLoginHelperInstance.account.accountToken)
                stdio.error("CREDB64=" + Qt.btoa(JSON.stringify(googleLoginHelperInstance.account)))
                window.close()
                application.quit()
            }
        }
    }

    Component {
        id: panelUnlock
        LauncherUnlock {
            onFinished: {
                next()
            }
        }
    }

    LauncherSettings {
        id: launcherSettings
    }

    Connections {
        target: window
        function onClosing() {
            application.quit()
        }
    }

    function needsToLogIn() {
        return googleLoginHelperInstance.account == null && !googleLoginHelperInstance.hasEncryptedCredentials && versionManagerInstance.versions.size === 0
    }

    Component.onCompleted: {
        next()
    }

    function next() {
        if (!googleLoginHelperInstance.isSupported()) {
            stackView.push(panelError)
        } else if (googleLoginHelperInstance.hasEncryptedCredentials && !hasAskedForKey) {
            hasAskedForKey = true
            stackView.push(panelUnlock)
        } else {
            defaultnext()
        }
    }

    function defaultnext() {
        stackView.push(panelDefault)
    }
}