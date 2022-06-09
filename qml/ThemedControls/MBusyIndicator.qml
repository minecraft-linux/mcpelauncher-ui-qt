import QtQuick
import QtQuick.Templates as T

T.BusyIndicator {

    id: control

    property color primaryColor: "#27a54a"
    property real barSpacing: 10

    implicitWidth: 70
    implicitHeight: 40

    contentItem: Item {

        id: item

        Repeater {
            id: repeater
            model: 3

            Rectangle {
                id: rect
                x: (control.width - barSpacing * (repeater.count - 1)) * index / repeater.count + barSpacing * index
                y: 0
                width: (control.width - barSpacing * (repeater.count - 1)) / repeater.count
                height: control.height
                color: primaryColor
                scale: 0.8

                SequentialAnimation {
                    id: anim
                    running: false

                    PropertyAnimation {
                        target: rect
                        property: "scale"
                        from: 0.8
                        to: 1
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                    PropertyAnimation {
                        target: rect
                        property: "scale"
                        to: 0.8
                        duration: 50
                        easing.type: Easing.InCubic
                    }

                }

                function startAnim() {
                    anim.start();
                }
            }
        }

    }

    Timer {
        running: control.visible && control.running
        interval: 200
        repeat: true

        property int index: 0

        onTriggered: function() {
            if (index == repeater.count) {
                index = 0;
                return;
            }
            repeater.itemAt(index).startAnim();
            index++;
        }
    }

}
