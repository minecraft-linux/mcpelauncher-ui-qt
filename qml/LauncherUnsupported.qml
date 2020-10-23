import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.2
import QtQuick.Controls 2.2
import "ThemedControls"
import io.mrarm.mcpelauncher 1.0

LauncherBase {
    property GoogleLoginHelper googleLoginHelper
    signal finished()
    id: rowLayout
    spacing: 0

    TextEdit {
        textFormat: TextEdit.RichText
        text: qsTr("<b><font color=\"#ff0000\">Sorry your Computer cannot run Minecraft with this Launcher</font></b>, this CPU is too old.<br/>Details:<br/>%1").arg(googleLoginHelper.GetSupportReport())
        readOnly: true
        wrapMode: Text.WordWrap
        selectByMouse: true
    }

    bottomPanelContent: RowLayout {
        anchors.fill: parent

        Layout.minimumWidth: pbutton.implicitWidth

        PlayButton {
            id: pbutton
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("I know what I'm doing")
            subText: qsTr("I won't expect any support")
            Layout.preferredHeight: 70
            Layout.minimumWidth: implicitWidth
            Layout.minimumHeight: implicitHeight
            onClicked: {
                rowLayout.finished()
            }
        }

    }

}
