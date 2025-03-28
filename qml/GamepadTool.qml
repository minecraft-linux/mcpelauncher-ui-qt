import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls
import "Components"
import io.mrarm.mcpelauncher 1.0

ApplicationWindow {
    id: gamepadTool
    width: 500
    height: 400
    minimumWidth: 400
    minimumHeight: 300
    title: qsTr("Gamepad Tool")
    color: "#333"

    property var currentGamepad: GamepadManager.gamepads.length > 0 ? GamepadManager.gamepads[0] : null

    ColumnLayout {
        anchors.centerIn: parent
        visible: !currentGamepad
        MText {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("No Gamepads Found!")
            font.bold: true
            font.pointSize: 12
        }
        MText {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("Ensure the gamepad is connected correctly.")
        }
    }

    ScrollView {
        visible: !!currentGamepad
        anchors.fill: parent
        contentWidth: parent.width - 30
        contentHeight: contentColumn.implicitHeight
        horizontalPadding: 15

        ColumnLayout {
            id: contentColumn
            spacing: 5
            width: parent.width

            MText {
                text: qsTr("Input")
                font.bold: true
                Layout.topMargin: 15
            }
            MComboBox {
                id: control
                Layout.fillWidth: true
                model: GamepadManager.gamepads.map(gamepad => gamepad.name)
                onActivated: function (index) {
                    currentGamepad = GamepadManager.gamepads[index]
                    console.log("onActivated: " + index + "/" + currentGamepad.guid)
                }
                onModelChanged: {
                    const gamepadIndex = GamepadManager.gamepads.indexOf(currentGamepad)
                    if (gamepadIndex !== -1) {
                        currentIndex = gamepadIndex
                    }
                    console.log("onModelChanged: " + gamepadIndex + currentGamepad)
                }
                Component.onCompleted: currentIndex = 0
            }

            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 80
                    MText {
                        text: qsTr("GUID")
                        font.bold: true
                        Layout.topMargin: 8
                    }
                    MTextField {
                        Layout.fillWidth: true
                        readOnly: true
                        text: currentGamepad ? currentGamepad.guid : ""
                        color: "#888"
                    }
                }
                ColumnLayout {
                    Layout.maximumWidth: 110
                    MText {
                        text: qsTr("Has Mapping")
                        font.bold: true
                        Layout.topMargin: 8
                    }
                    MTextField {
                        Layout.fillWidth: true
                        readOnly: true
                        color: "#888"
                        text: currentGamepad && currentGamepad.hasMapping ? "True" : "False"
                    }
                }
            }

            MText {
                text: qsTr("Set Mapping")
                font.bold: true
                Layout.topMargin: 15
            }
            GridLayout {
                columns: Math.floor(parent.width / 220)
                columnSpacing: 8
                rowSpacing: 8
                Repeater {
                    id: inputRepeater
                    model: ["a", "b", "x", "y", "leftshoulder", "rightshoulder", "righttrigger", "lefttrigger", "back", "start", "leftstick", "rightstick", "guide", "dpleft", "dpdown", "dpright", "dpup", "leftx", "lefty", "rightx", "righty"]
                    Rectangle {
                        id: field
                        color: "#222"
                        border.color: "#444"
                        Layout.fillWidth: true
                        Layout.minimumHeight: 48

                        property string name: modelData
                        property var gamepad: currentGamepad
                        property string key: ""
                        property bool waiting: false

                        property var oldButtons: []
                        property var oldAxes: []
                        property var oldHats: []

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 2
                            MText {
                                text: field.name.toUpperCase()
                                Layout.fillWidth: true
                            }
                            MText {
                                text: field.waiting ? qsTr("Waiting") : field.key.toUpperCase()
                                color: field.waiting ? "#888" : "#af8"
                                Layout.rightMargin: 5
                            }
                            MButton {
                                Layout.preferredHeight: 28
                                horizontalPadding: 4
                                text: "..."
                                onClicked: {
                                    key = ""
                                    if (waiting) {
                                        GamepadManager.enabled = true
                                        waiting = false
                                        return
                                    }
                                    if (GamepadManager.enabled) {
                                        GamepadManager.enabled = false
                                        waiting = true

                                        oldButtons = gamepad.buttons.slice()
                                        oldAxes = gamepad.axes.slice()
                                        oldHats = gamepad.hats.slice()

                                        inputCaptureTimer.start()
                                    }
                                }
                            }
                        }

                        Timer {
                            id: inputCaptureTimer
                            interval: 100
                            repeat: true
                            running: waiting
                            onTriggered: {
                                for (var i = 0; i < gamepad.buttons.length; i++) {
                                    if (oldButtons[i] !== gamepad.buttons[i]) {
                                        setKey("b" + i)
                                        return
                                    }
                                }
                                for (var i = 0; i < gamepad.axes.length; i++) {
                                    if (Math.abs(oldAxes[i] - gamepad.axes[i]) > 0.5) {
                                        setKey("a" + i)
                                        return
                                    }
                                }
                                for (var i = 0; i < gamepad.hats.length; i++) {
                                    if (oldHats[i] !== gamepad.hats[i]) {
                                        setKey("h" + i + "." + gamepad.hats[i])
                                        return
                                    }
                                }
                            }
                        }

                        function setKey(keyText) {
                            GamepadManager.enabled = true
                            waiting = false
                            key = keyText
                            inputCaptureTimer.stop()
                        }
                    }
                }
            }

            MText {
                text: qsTr("Mapping")
                font.bold: true
                Layout.topMargin: 15
            }
            MTextField {
                id: gamepadMapping
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                readOnly: true
                color: "#888"
                text: {
                    if (!currentGamepad)
                        return ""
                    var fields = [currentGamepad.guid, currentGamepad.name]
                    for (var i = 0; i < inputRepeater.count; i++) {
                        const it = inputRepeater.itemAt(i)
                        if (it.key) {
                            fields.push(`${it.name}:${it.key}`)
                        }
                    }
                    return fields.join(",")
                }
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 15
                columns: parent.width > 500 ? 2 : 1
                MButton {
                    Layout.fillWidth: true
                    text: qsTr("Save to current profile")
                    onClicked: saveMapping(window.getCurrentGameDataDir())
                }
                MButton {
                    Layout.fillWidth: true
                    text: qsTr("Save to default directory")
                    onClicked: saveMapping(launcherSettings.gameDataDir)
                }
            }
        }
    }

    function saveMapping(path) {
        console.log(`Saved to ${path} : ${gamepadMapping.text}`)
        GamepadManager.saveMapping(QmlUrlUtils.urlToLocalFile(path), gamepadMapping.text)
    }

    footer: Rectangle {
        height: pbutton.height + 20
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
