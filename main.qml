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
        initialItem: panelLogin
    }


    GoogleLoginHelper {
        id: googleLoginHelperInstance
    }

    Component {
        id: panelLogin

        LauncherLogin {
            googleLoginHelper: googleLoginHelperInstance
            onFinished: stackView.replace(panelMain)
        }
    }

    Component {
        id: panelMain

        LauncherMain {
        }
    }


}
