import QtQuick
import QtQuick.Layouts
import "ThemedControls"

ColumnLayout {
    id: columnlayout
    width: parent.width
    spacing: 10

    TextEdit {
        Layout.fillWidth: true
        text: qsTr("If Qt6 fails to open the folder it doesn't report back") + ": https://doc.qt.io/qt-6/qml-qtqml-qt.html#openUrlExternally-method"
        color: "#fff"
        font.pointSize: 10
        readOnly: true
        wrapMode: Text.WordWrap
        selectByMouse: true
    }

    HorizontalDivider {}

    Text {
        Layout.fillWidth: true
        text: qsTr("Game Directories")
        font.bold: true
        font.pointSize: 10
        color: "#fff"
    }

    GridLayout {
        Layout.fillWidth: true
        columns: parent.width < 600 ? 2 : 4

        MButton {
            text: qsTr("Open Data Root")
            Layout.fillWidth: true
            onClicked: Qt.openUrlExternally(window.getCurrentGameDataDir())
        }
        MButton {
            text: qsTr("Open Worlds")
            Layout.fillWidth: true
            onClicked: Qt.openUrlExternally(window.getCurrentGameDataDir() + "/games/com.mojang/minecraftWorlds")
        }
        MButton {
            text: qsTr("Open Resource Packs")
            Layout.fillWidth: true
            onClicked: Qt.openUrlExternally(window.getCurrentGameDataDir() + "/games/com.mojang/resource_packs")
        }
        MButton {
            text: qsTr("Open Behavior Packs")
            Layout.fillWidth: true
            onClicked: Qt.openUrlExternally(window.getCurrentGameDataDir() + "/games/com.mojang/behavior_packs")
        }
    }
}
