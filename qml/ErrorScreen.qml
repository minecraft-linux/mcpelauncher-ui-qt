import QtQuick
import QtQuick.Window
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls
import "Components"
import io.mrarm.mcpelauncher 1.0

BaseScreen {
    id: errorScreen
    property var message: qsTr("<b><font color=\"#f66\">Not logged in</font></b>")
    property var confirm: qsTr("Authorize the mod to access your Google Credentials")

    signal finished

    headerContent: TabBar {
        background: null
        MTabButton {
            text: qsTr("Info")
        }
    }

    TextEdit {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.margins: 15
        textFormat: TextEdit.RichText
        text: errorScreen.message
        font.pointSize: 10
        color: "#fff"
        readOnly: true
        wrapMode: Text.WordWrap
        selectByMouse: true
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.minimumHeight: pbutton.height + 10 * 2

        color: "#242424"

        MButton {
            id: pbutton
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 10
            text: errorScreen.confirm
            onClicked: {
                errorScreen.finished()
            }
        }
    }
}
