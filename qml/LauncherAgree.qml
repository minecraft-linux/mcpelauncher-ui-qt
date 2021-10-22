import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.2
import QtQuick.Controls 2.2
import "ThemedControls"
import io.mrarm.mcpelauncher 1.0

LauncherBase {

    signal finished()
    id: rowLayout
    spacing: 0

    ColumnLayout {
        Layout.fillHeight: true
        Layout.fillWidth: true
        TextEdit {
            Layout.fillHeight: true
            Layout.fillWidth: true
            textFormat: TextEdit.RichText
            text: "<h1>Some Launcher Settings need your Attention</h1><p>Due to ongoing abuse of this Launcher for piracy it is required to check your license in proprietary Launcher Extensions, which allow you to run 1.17.40+ if and only if your own the game</p><p>If you disable them, this launcher will still be able to open Minecraft &lt;= 1.17.34 as before and receive open source bugfix updates. Only new version support will stop to mitigate piracy. All Members of http://github.com/minecraft-linux have access to the source code of the launcher Extensions</p>"
            readOnly: true
            anchors.fill: parent
            wrapMode: Text.WordWrap
            selectByMouse: true
        }
        MCheckBox {
            id: box
            text: qsTr("Allow proprietary Launcher Extensions")
            font.pointSize: parent.labelFontSize
            Component.onCompleted: checked = launcherSettings.allowLauncherExtensions
            onCheckedChanged: launcherSettings.allowLauncherExtensions = checked
        }
    }

    bottomPanelContent: RowLayout {
        anchors.fill: parent

        Layout.minimumWidth: pbutton.implicitWidth

        PlayButton {
            id: pbutton
            Layout.alignment: Qt.AlignHCenter
            text: "Continue"
            Layout.preferredHeight: 70
            Layout.minimumWidth: implicitWidth
            Layout.minimumHeight: implicitHeight
            onClicked: {
                rowLayout.finished()
            }
        }

    }
}
