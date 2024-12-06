import QtQuick
import QtQuick.Window
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls
import "Components"
import io.mrarm.mcpelauncher 1.0

Window {
    id: gamepadTool
    width: 500
    height: 400
    minimumWidth: 500
    minimumHeight: 400
    title: qsTr("Gamepad Tool")
    color: "#333"

    property int margin: 10
    property bool hasGamepad: GamepadManager.gamepads.length > 0 && control.currentIndex >= 0 && control.currentIndex < GamepadManager.gamepads.length

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

                property string currentGamepad: ""

                model: {
                    var ret = []
                    for (var i = 0; i < GamepadManager.gamepads.length; i++) {
                        ret.push(GamepadManager.gamepads[i].name)
                    }
                    console.log(JSON.stringify(ret))
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
                        color: "#fff"
                        anchors.topMargin: 0
                        text: modelData
                        font.pointSize: 11
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Layout.fillWidth: true

                onActivated: function (index) {
                    currentGamepad = GamepadManager.gamepads[index].guid
                    console.log("onActivated: " + index + "/" + currentGamepad)
                    currentIndex = index
                    console.log(currentIndex)
                }

                onModelChanged: {
                    for (var i = 0; i < GamepadManager.gamepads.length; i++) {
                        if (GamepadManager.gamepads[i].guid == currentGamepad) {
                            console.log("onModelChanged: found ")
                            currentIndex = i
                            break
                        }
                    }
                    console.log("onModelChanged: " + currentGamepad)
                    console.log("onModelChanged: " + currentIndex)
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
                color: "#fff"
            }

            Repeater {
                id: inputRepeater
                model: ["a", "b", "x", "y", "leftshoulder", "rightshoulder", "righttrigger", "lefttrigger", "back", "start", "leftstick", "rightstick", "guide", "dpleft", "dpdown", "dpright", "dpup", "leftx", "lefty", "rightx", "righty"]
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
                    if (gamepadTool.hasGamepad) {
                        var fields = []
                        fields.push(GamepadManager.gamepads[control.currentIndex].guid)
                        fields.push(GamepadManager.gamepads[control.currentIndex].name)
                        for (var i = 0; i < inputRepeater.count; i++) {
                            var key = inputRepeater.itemAt(i).key
                            if (key && key.length > 0) {
                                fields.push(inputRepeater.itemAt(i).name + ":" + key)
                            }
                        }
                        return fields.join(",")
                    }
                    return qsTr("No Gamepad")
                }
            }

            MButton {
                Layout.fillWidth: true
                Layout.leftMargin: gamepadTool.margin
                Layout.rightMargin: gamepadTool.margin
                text: qsTr("Save Mapping to current Profile")
                enabled: gamepadTool.hasGamepad
                onClicked: {
                    console.log(gamepadMapping.text)
                    console.log(QmlUrlUtils.urlToLocalFile(window.getCurrentGameDataDir()))
                    GamepadManager.saveMapping(QmlUrlUtils.urlToLocalFile(window.getCurrentGameDataDir()), gamepadMapping.text)
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
                    console.log(gamepadMapping.text)
                    console.log(QmlUrlUtils.urlToLocalFile(launcherSettings.gameDataDir))
                    GamepadManager.saveMapping(QmlUrlUtils.urlToLocalFile(launcherSettings.gameDataDir), gamepadMapping.text)
                }
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
                    text: qsTr("Close")
                    onClicked: gamepadTool.close()
                }
            }
        }
    }
}
