import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

T.Button {
    id: control
    property string subText: ""

    implicitHeight: contentItem.implicitHeight + 30
    implicitWidth: contentItem.implicitWidth + 30

    background: BorderImage {
        id: buttonBackground
        source: "qrc:/Resources/green-button.png"
        smooth: false
        border {
            left: 8
            top: 8
            right: 8
            bottom: 8
        }
        horizontalTileMode: BorderImage.Stretch
        verticalTileMode: BorderImage.Stretch
        Rectangle {
            id: backgroundOverlay
            anchors.centerIn: parent
            width: parent.width - 2 * 8
            height: parent.height - 2 * 8
            color: "#1f1"
            opacity: 0
        }
        FocusBorder {
            visible: control.visualFocus
        }
    }

    contentItem: Item {
        implicitWidth: content.implicitWidth
        implicitHeight: content.implicitHeight

        ColumnLayout {
            id: content
            spacing: 0
            anchors.centerIn: parent
            Text {
                id: textItem
                text: control.text
                font {
                    pointSize: 14
                    bold: true
                }
                opacity: enabled ? 1.0 : 0.3
                color: "#fff"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            Text {
                id: subTextItem
                visible: control.subText.length > 0
                text: control.subText
                font.pointSize: 9
                opacity: enabled ? 1.0 : 0.3
                color: "#fff"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }
    }

    states: State {
        name: "hovered"
        when: control.hovered && !control.down && control.enabled
    }

    transitions: [
        Transition {
            to: "hovered"
            NumberAnimation {
                target: buttonBackground
                property: "scale"
                to: 1.05
                duration: 150
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: backgroundOverlay
                property: "opacity"
                to: 0.2
                duration: 100
                easing.type: Easing.OutCubic
            }
        },
        Transition {
            to: "*"
            NumberAnimation {
                target: buttonBackground
                property: "scale"
                to: 1
                duration: 100
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: backgroundOverlay
                property: "opacity"
                to: 0
                duration: 100
                easing.type: Easing.OutCubic
            }
        }
    ]
}
