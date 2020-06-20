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
    minimumWidth: 640
    minimumHeight: 480
    title: qsTr("Linux Minecraft Launcher")
    flags: Qt.Dialog

    StackView {
        id: stackView
        anchors.fill: parent
    }


    GoogleLoginHelper {
        id: googleLoginHelperInstance
        onWarnUnsupportedABI: function(abis, unsupported) {
            warnUnsupportedABIDialog.title = unsupported ? "Minecraft Android cannot run on your PC" : "Please login again"
            warnUnsupportedABIDialog.text = unsupported ? "Sorry your Device cannot run Minecraft with this Launcher, your Computer is likely too old": "Please logout and login again (in Settings) to fix this problem\nFurther Information: Unsupported android architectures for this device or launcher are " + abis.join(", ")
            warnUnsupportedABIDialog.open()
        }
    }

    VersionManager {
        id: versionManagerInstance
    }

    ProfileManager {
        id: profileManagerInstance
    }

    Component {
        id: panelLogin

        LauncherLogin {
            googleLoginHelper: googleLoginHelperInstance
            versionManager: versionManagerInstance
            onFinished: stackView.replace(panelMain)
        }
    }

    Component {
        id: panelMain

        LauncherMain {
            googleLoginHelper: googleLoginHelperInstance
            versionManager: versionManagerInstance
            profileManager: profileManagerInstance
        }
    }

    LauncherSettings {
        id: launcherSettings
    }

    function needsToLogIn() {
        return googleLoginHelperInstance.account == null && versionManagerInstance.versions.size === 0
    }

    Component.onCompleted: {
        if (needsToLogIn()) {
            stackView.push(panelLogin);
        } else {
            stackView.push(panelMain);
        }
    }

}
