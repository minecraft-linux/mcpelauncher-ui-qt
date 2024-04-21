import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

T.Button {
    id: control
    property alias iconSource: icon.source
    property alias showText: text.visible

    implicitHeight: 50
    implicitWidth: implicitContentWidth

    background: Item {
        Rectangle {
            id: indicatorBar
            color: "#eee"
            width: 3
            height: 0
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
        }
        FocusBorder {
            visible: control.visualFocus
        }
    }

    contentItem: RowLayout {
        opacity: (control.hovered && !control.checked) ? 0.85 : 1
        height: control.height

        Image {
            id: icon
            width: 30
            source: iconSource
            smooth: false
            fillMode: Image.PreserveAspectFit
            Layout.leftMargin: 18
            Layout.rightMargin: 18
        }

        Text {
            id: text
            color: "#fff"
            text: control.text
            font.pointSize: 11
            font.bold: checked
            verticalAlignment: Text.AlignVCenter
            Layout.fillHeight: true
            Layout.rightMargin: 40
        }
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
                property: "height"
                to: 25
                duration: 200
                easing.type: Easing.OutCubic
            }
        },
        Transition {
            to: "*"
            NumberAnimation {
                target: indicatorBar
                property: "height"
                to: 0
                duration: 180
                easing.type: Easing.OutQuad
            }
        }
    ]
}
