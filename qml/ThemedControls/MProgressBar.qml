import QtQuick
import QtQuick.Templates as T

T.ProgressBar {
    id: control
    padding: 2
    property string label: ""

    background: Rectangle {
        anchors.fill: parent
        color: "#1e1e1e"
    }

    contentItem: Item {
        Rectangle {
            width: parent.width * control.visualPosition
            height: parent.height
            color: "#008643"
            visible: !control.indeterminate
        }

        Item {
            clip: true
            anchors.fill: parent
            visible: control.indeterminate
            Rectangle {
                id: bar
                color: "#008643"
                height: parent.height
                NumberAnimation on x {
                    from: -control.width / 8
                    to: control.width
                    loops: Animation.Infinite
                    running: control.indeterminate
                    duration: 1200
                    easing.type: Easing.InOutCubic
                }

                NumberAnimation on width {
                    from: control.width / 10
                    to: control.width / 2
                    loops: Animation.Infinite
                    running: control.indeterminate
                    duration: 1200
                    easing.type: Easing.InOutCubic
                }
            }
        }

        Text {
            text: control.label
            color: "#fff"
            font.pointSize: 10
            anchors.fill: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
