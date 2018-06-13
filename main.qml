import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Controls 2.1

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

    Component {
        id: panelLogin

        LauncherLogin { }
    }

    Component {
        id: panelMain

        LauncherMain { }
    }


}
