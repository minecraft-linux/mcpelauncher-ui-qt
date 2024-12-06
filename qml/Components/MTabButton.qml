import QtQuick
import QtQuick.Templates as T

T.TabButton {
    id: control
    padding: 15
    implicitWidth: 15 + fontMetrics.boundingRect(contentItem.text).width + leftPadding + rightPadding
    implicitHeight: 40
    anchors.bottom: parent.bottom

    indicator: Rectangle {
        id: indicatorBar
        color: "#9c6"
        width: 0
        height: 3
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
    }

    background: FocusBorder {
        visible: control.visualFocus
    }

    FontMetrics {
        id: fontMetrics
        font.pointSize: contentItem.font.pointSize
        font.bold: true
    }

    contentItem: Text {
        text: control.text
        font.pointSize: 11
        font.bold: checked
        opacity: enabled ? (checked ? 1.0 : hovered ? 0.9 : 0.7) : 0.3
        color: "#fff"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    states: State {
        name: "checked"
        when: control.checked
    }

    transitions: [
        Transition {
            to: "checked"
            NumberAnimation {
                target: indicatorBar
                property: "width"
                to: 30
                duration: 250
                easing.type: Easing.OutCubic
            }
        },
        Transition {
            to: "*"
            NumberAnimation {
                target: indicatorBar
                property: "width"
                to: 0
                duration: 180
                easing.type: Easing.OutQuad
            }
        }
    ]
}
