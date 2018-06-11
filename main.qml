import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.11
import "ThemedControls"

Window {
    id: window
    visible: true
    width: 640
    height: 480
    title: qsTr("Linux Minecraft Launcher")
    flags: Qt.Dialog

    ColumnLayout {
        id: rowLayout
        spacing: 0
        anchors.fill: parent

        Rectangle {
            id: appbar
            height: 50
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            color: "#000"

            RowLayout {
                anchors.fill: parent

                TransparentButton {
                    text: "This is a test"
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    //
                }

            }

        }
    }

}
