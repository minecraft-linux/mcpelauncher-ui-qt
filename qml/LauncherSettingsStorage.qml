import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.2
import QtQuick.Controls 2.2
import "ThemedControls"

GridLayout {
    Layout.fillHeight: true
    Layout.fillWidth: true
    columns: 2
    property int labelFontSize: 12
    property string lastPath: ""

    TextEdit {
        Layout.columnSpan: 2
        textFormat: TextEdit.RichText
        text: "If qt5 fails to open the folder it doesn't report back: https://doc.qt.io/qt-5/qml-qtqml-qt.html#openUrlExternally-method"
        readOnly: true
        wrapMode: Text.WordWrap
        selectByMouse: true
        Layout.fillWidth: true
    }

    MButton {
        text: qsTr("Open Data Root")
        Layout.columnSpan: 1
        Layout.fillWidth: true
        onClicked: Qt.openUrlExternally(window.getCurrentGameDataDir())
    }

    MButton {
        text: qsTr("Open Worlds")
        Layout.columnSpan: 1
        Layout.fillWidth: true
        onClicked: Qt.openUrlExternally(window.getCurrentGameDataDir() + "/games/com.mojang/minecraftWorlds")
    }
    MButton {
        text: qsTr("Open Resource Packs")
        Layout.columnSpan: 1
        Layout.fillWidth: true
        onClicked: Qt.openUrlExternally(window.getCurrentGameDataDir() + "/games/com.mojang/resource_packs")
    }
    MButton {
        text: qsTr("Open Behavior Packs")
        Layout.columnSpan: 1
        Layout.fillWidth: true
        onClicked: Qt.openUrlExternally(window.getCurrentGameDataDir() + "/games/com.mojang/behavior_packs")
    }
}