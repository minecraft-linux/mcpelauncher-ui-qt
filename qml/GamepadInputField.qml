import QtQuick 2.4

import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.2
import "ThemedControls"
import io.mrarm.mcpelauncher 1.0

RowLayout {
    Layout.fillWidth: true
    spacing: 2
    id: layout

    property var name: ""
    property var hasGamepad: true
    property var gamepad: layout.hasGamepad ? GamepadManager.gamepads[control.currentIndex] : null
    property var key: change.active ? "" : btna.text

    Text {
        id: name
        text: layout.name
        Layout.fillWidth: true
    }

    Text {
        id: btna
        text: ""
    }

    MButton {
        id: change
        property var active: false
        text: "..."
        onClicked: {
            if(active || !layout.hasGamepad) {
                active = false;
                btna.text = "";
                return "";
            }
            active = true;
            var oldButtons = [];
            for(var i = 0; i < layout.gamepad.buttons.length; i++) {
                oldButtons.push(layout.gamepad.buttons[i]);
            }
            var oldAxes = [];
            for(var i = 0; i < layout.gamepad.axes.length; i++) {
                oldAxes.push(layout.gamepad.axes[i]);
            }
            if(GamepadManager.enabled) {
                btna.text = Qt.binding(function() {
                    if(!layout.hasGamepad) {
                        active = false;
                        btna.text = "";
                        return;
                    }
                    GamepadManager.enabled = false;
                    for(var i = 0; i < layout.gamepad.buttons.length; i++) {
                        if(oldButtons[i] != layout.gamepad.buttons[i]) {
                            active = false;
                            btna.text = "b" + i;
                            GamepadManager.enabled = true;
                            return "";
                        }
                    }
                    for(var i = 0; i < layout.gamepad.axes.length; i++) {
                        if(Math.abs(oldAxes[i] - layout.gamepad.axes[i]) > 0.5) {
                            active = false;
                            btna.text = "a" + i;
                            GamepadManager.enabled = true;
                            return "";
                        }
                    }
                    return "waiting";
                });
            }
        }
    }
}