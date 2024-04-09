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
    }

    contentItem: Item {
        implicitWidth: content.implicitWidth
        implicitHeight: content.implicitHeight

        ColumnLayout {
            id: content
            spacing: 0
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
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
        PropertyChanges {
            target: buttonBackground
            scale: 1.05
        }
    }

    transitions: [
        Transition {
            to: "hovered"
            reversible: true
            PropertyAnimation {
                target: buttonBackground
                property: "scale"
                duration: 100
                easing.type: Easing.InOutCubic
            }
        }
    ]
}
