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

                property var currentGamepad: ""
                
                model: {
                    var ret = []
                    if(GamepadManager.gamepads) {
                        //console.log(JSON.stringify(GamepadManager.gamepads));
                        for (var i = 0; i < GamepadManager.gamepads.length; i++) {
                            ret.push(GamepadManager.gamepads[i].name);
                        }
                    }
                    console.log(ret);
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
                readOnly: true
                text: GamepadManager.gamepads[control.currentIndex].guid
            }

            MTextField {
                Layout.fillWidth: true
                readOnly: true
                text: GamepadManager.gamepads[control.currentIndex].name
            }

            Text {
                text: "Has a gamepad Mapping? " + (GamepadManager.gamepads[control.currentIndex].hasMapping ? "true" : "false")
            }

            Repeater {
                id: inputRepeater
                property var content: [ "a", "b", "x", "y", "leftshoulder", "rightshoulder", "righttrigger", "lefttrigger", "back", "start", "leftstick", "rightstick", "guide", "dpleft", "dpdown", "dpright", "dpup", "leftx", "lefty", "rightx", "righty" ]
                model: inputRepeater.content.length
                GamepadInputField {
                    required property int index
                    name: inputRepeater.content[index]
                }
            }

            MTextField {
                id: gamepadMapping
                Layout.fillWidth: true
                readOnly: true
                text: {
                    console.log("mapping");
                    if(GamepadManager.gamepads) {
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
                    return "No Gamepad";
                }
            }
            MButton {
                Layout.fillWidth: true
                text: "Save Mapping"
                onClicked: {
                    console.log(gamepadMapping.text);
                    console.log(QmlUrlUtils.urlToLocalFile(window.getCurrentGameDataDir()));
                    GamepadManager.saveMapping(QmlUrlUtils.urlToLocalFile(window.getCurrentGameDataDir()), gamepadMapping.text);
                }
            }
        }
    }
}
