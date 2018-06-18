import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Controls 2.1
import io.mrarm.mcpelauncher 1.0

Window {
    id: window
    visible: true
    width: 640
    height: 480
    title: qsTr("Linux Minecraft Launcher")
    flags: Qt.Dialog

    StackView {
        id: stackView
        anchors.fill: parent
    }


    GoogleLoginHelper {
        id: googleLoginHelperInstance
    }

    VersionManager {
        id: versionManagerInstance
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
        }
    }

    function needsToLogIn() {
        return googleLoginHelperInstance.account == null && versionManagerInstance.listVersions().length === 0
    }

    Component.onCompleted: {
        if (needsToLogIn()) {
            stackView.push(panelLogin);
        } else {
            stackView.push(panelMain);
        }
    }

}
