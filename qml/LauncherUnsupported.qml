import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.2
import QtQuick.Controls 2.2
import "ThemedControls"
import io.mrarm.mcpelauncher 1.0

LauncherBase {
    property GoogleLoginHelper googleLoginHelper
    signal finished
    id: rowLayout
    spacing: 0

    TextEdit {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.margins: 15
        textFormat: TextEdit.RichText
        text: qsTr("<b><font color=\"#f66\">Sorry your Computer cannot run Minecraft with this Launcher</font></b>, this CPU is too old.<br/><br/>Details:<br/>%1").arg(googleLoginHelper.GetSupportReport())
        font.pointSize: 11
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
                rowLayout.finished()
            }
        }
    }
}
