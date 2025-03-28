import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "Components"
import io.mrarm.mcpelauncher 1.0

BaseScreen {
    id: changelogScreen

    signal finished

    headerContent: TabBar {
        background: null
        MTabButton {
            text: qsTr("Changelog")
        }
    }

    ScrollView {
        Layout.fillHeight: true
        Layout.fillWidth: true
        contentWidth: availableWidth
        TextEdit {
            padding: 15
            textFormat: TextEdit.RichText
            text: "<b>Welcome to the new Minecraft Linux Launcher Update</b><br/><br/>" + LAUNCHER_CHANGE_LOG
            color: "#fff"
            readOnly: true
            font.pointSize: 10
            wrapMode: Text.WordWrap
            selectByMouse: true
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
            onClicked: changelogScreen.finished()
        }
    }
}
