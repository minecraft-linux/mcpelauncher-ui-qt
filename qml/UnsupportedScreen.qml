import QtQuick
import QtQuick.Window
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls
import "Components"
import io.mrarm.mcpelauncher 1.0

BaseScreen {
    id: unsupportedScreen

    property GoogleLoginHelper googleLoginHelper
    signal finished

    headerContent: TabBar {
        background: null
        MTabButton {
            text: qsTr("Info")
        }
    }

    TextEdit {
        Layout.fillHeight: true
        Layout.margins: 15
        textFormat: TextEdit.RichText
        text: qsTr("<b><font color=\"#f66\">Sorry your Computer cannot run Minecraft with this Launcher</font></b>, this CPU is too old.<br/><br/>Details:<br/>%1").arg(googleLoginHelper.GetSupportReport())
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
            text: qsTr("I know what I'm doing")
            onClicked: {
                unsupportedScreen.finished()
            }
        }
    }
}
