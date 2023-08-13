import QtQuick 2.4

import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.2
import "ThemedControls"
import io.mrarm.mcpelauncher 1.0

Window {

    id: gamepadTool
    width: 500
    height: 400
    minimumWidth: 500
    minimumHeight: 400
    title: qsTr("Gamepad Tool")

    property var margin: 10
    property var hasGamepad: GamepadManager.gamepads.length > 0 && control.currentIndex >= 0 && control.currentIndex < GamepadManager.gamepads.length

    ScrollView {
        anchors.fill: parent

        clip: true
        ColumnLayout {
            spacing: 0
            Layout.fillHeight: true
            width: gamepadTool.width
            Layout.fillWidth: true

            
            MComboBox {
                id: control

                Layout.topMargin: gamepadTool.margin
                Layout.leftMargin: gamepadTool.margin
                Layout.rightMargin: gamepadTool.margin

                property var currentGamepad: ""
                
                model: {
                    var ret = [];
                    for (var i = 0; i < GamepadManager.gamepads.length; i++) {
                        ret.push(GamepadManager.gamepads[i].name);
                    }
                    console.log(JSON.stringify(ret));
                    return ret
                }

                delegate: ItemDelegate {
                    width: parent.width
                    height: 32
                    text: modelData
                    highlighted: control.highlightedIndex === index

                    contentItem: Text {
                        anchors.fill: parent
                        anchors.leftMargin: parent.padding
                        anchors.rightMargin: parent.padding
                        anchors.topMargin: 0
                        text: modelData
                        font.pointSize: 11
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Layout.fillWidth: true

                onActivated: function(index) {
                    currentGamepad = GamepadManager.gamepads[index].guid;
                    console.log("onActivated: " + index + "/" + currentGamepad);
                    currentIndex = index;
                    console.log(currentIndex);
                }

                onModelChanged: {
                    for (var i = 0; i < GamepadManager.gamepads.length; i++) {
                        if(GamepadManager.gamepads[i].guid == currentGamepad) {
                            console.log("onModelChanged: found ");
                            currentIndex = i;
                            break;
                        }
                    }
                    console.log("onModelChanged: " + currentGamepad);
                    console.log("onModelChanged: " + currentIndex);
                }
            }

            MTextField {
                Layout.fillWidth: true
                Layout.leftMargin: gamepadTool.margin
                Layout.rightMargin: gamepadTool.margin
                readOnly: true
                text: gamepadTool.hasGamepad ? GamepadManager.gamepads[control.currentIndex].guid : qsTr("No Gamepad")
            }

            MTextField {
                Layout.fillWidth: true
                Layout.leftMargin: gamepadTool.margin
                Layout.rightMargin: gamepadTool.margin
                readOnly: true
                text: gamepadTool.hasGamepad ? GamepadManager.gamepads[control.currentIndex].name : qsTr("No Gamepad")
            }

            Text {
                Layout.leftMargin: gamepadTool.margin
                Layout.rightMargin: gamepadTool.margin
                text: "Has a gamepad Mapping? " + (gamepadTool.hasGamepad && GamepadManager.gamepads[control.currentIndex].hasMapping ? "true" : "false")
            }

            Repeater {
                id: inputRepeater
                model: [ "a", "b", "x", "y", "leftshoulder", "rightshoulder", "righttrigger", "lefttrigger", "back", "start", "leftstick", "rightstick", "guide", "dpleft", "dpdown", "dpright", "dpup", "leftx", "lefty", "rightx", "righty" ]
                GamepadInputField {
                    Layout.leftMargin: gamepadTool.margin
                    Layout.rightMargin: gamepadTool.margin
                    name: modelData
                    gamepad: gamepadTool.hasGamepad ? GamepadManager.gamepads[control.currentIndex] : null
                }
            }

            MTextField {
                id: gamepadMapping
                Layout.fillWidth: true
                Layout.leftMargin: gamepadTool.margin
                Layout.rightMargin: gamepadTool.margin
                readOnly: true
                text: {
                    if(gamepadTool.hasGamepad) {
                        var fields = [];
                        fields.push(GamepadManager.gamepads[control.currentIndex].guid);
                        fields.push(GamepadManager.gamepads[control.currentIndex].name);
                        for(var i = 0; i < inputRepeater.count; i++) {
                            var key = inputRepeater.itemAt(i).key;
                            if(key && key.length > 0) {
                                fields.push(inputRepeater.itemAt(i).name + ":" + key);
                            }
                        }
                        return fields.join(",");
                    }
                    return qsTr("No Gamepad");
                }
            }

            MButton {
                Layout.fillWidth: true
                Layout.leftMargin: gamepadTool.margin
                Layout.rightMargin: gamepadTool.margin
                text: qsTr("Save Mapping to current Profile")
                enabled: gamepadTool.hasGamepad
                onClicked: {
                    console.log(gamepadMapping.text);
                    console.log(QmlUrlUtils.urlToLocalFile(window.getCurrentGameDataDir()));
                    GamepadManager.saveMapping(QmlUrlUtils.urlToLocalFile(window.getCurrentGameDataDir()), gamepadMapping.text);
                }
            }

            MButton {
                Layout.fillWidth: true
                Layout.leftMargin: gamepadTool.margin
                Layout.rightMargin: gamepadTool.margin
                Layout.bottomMargin: gamepadTool.margin
                text: qsTr("Save Mapping to default Data directory")
                enabled: gamepadTool.hasGamepad
                onClicked: {
                    console.log(gamepadMapping.text);
                    console.log(QmlUrlUtils.urlToLocalFile(launcherSettings.gameDataDir));
                    GamepadManager.saveMapping(QmlUrlUtils.urlToLocalFile(launcherSettings.gameDataDir), gamepadMapping.text);
                }
            }
            
            Image {
                id: buttons
                smooth: false
                fillMode: Image.Tile
                source: "qrc:/Resources/noise.png"
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true
                Layout.preferredHeight: 50

                RowLayout {
                    x: parent.width / 2 - width / 2
                    y: parent.height / 2 - height / 2

                    spacing: 20

                    PlayButton {
                        Layout.preferredWidth: 150
                        text: qsTr("Close")
                        onClicked: gamepadTool.close()
                    }

                }

            }
        }
    }
}
