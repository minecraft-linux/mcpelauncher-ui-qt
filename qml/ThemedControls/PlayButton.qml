import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

T.Button {
    id: control

    property string subText: ""

    padding: 8
    implicitWidth: 10 / 9 * contentItem.implicitWidth + leftPadding + rightPadding
    implicitHeight: 10 / 9 * contentItem.implicitHeight + topPadding + bottomPadding
    Layout.minimumWidth: implicitHeight
    Layout.minimumHeight: implicitHeight
    baselineOffset: contentItem.y + contentItem.baselineOffset

    background: BorderImage {
        id: buttonBackground
        source: "qrc:/Resources/green-button.png"
        smooth: false
        border { left: 5; top: 5; right: 5; bottom: 5 }
        horizontalTileMode: BorderImage.Stretch
        verticalTileMode: BorderImage.Stretch
        scale: 0.9

        Rectangle {
            id: buttonBackgroundOverlay
            anchors.fill: background
            color: "#20000000"
            opacity: 0
        }
    }

    contentItem: Item {
        implicitWidth: content.implicitWidth
        implicitHeight: content.implicitHeight
        ColumnLayout {
            id: content
            spacing: 3
            x: width * (0.05)
            width: parent.width * 0.9
            y: parent.height * 0.9 / 2 - height / 2
            Text {
                id: textItem
                text: control.text
                font.pointSize: 16
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
                font.pointSize: 10
                opacity: enabled ? 1.0 : 0.3
                color: "#fff"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }
    }

    states: [
        State {
            name: "normal"
            when: !control.hovered
        },
        State {
            name: "hovered"
            when: control.hovered
            PropertyChanges {
                target: buttonBackground
                scale: 1.0
            }
            PropertyChanges {
                target: buttonBackgroundOverlay
                opacity: 1
            }
        }
    ]

    transitions: [
        Transition {
            from: "normal"
            to: "hovered"
            PropertyAnimation { target: buttonBackground; property: "scale"; duration: 100; easing.type: Easing.InSine}
            PropertyAnimation { target: buttonBackgroundOverlay; property: "opacity"; duration: 100; easing.type: Easing.InSine}
        },
        Transition {
            from: "hovered"
            to: "normal"
            PropertyAnimation { target: buttonBackground; property: "scale"; duration: 100; easing.type: Easing.OutSine}
            PropertyAnimation { target: buttonBackgroundOverlay; property: "opacity"; duration: 100; easing.type: Easing.OutSine}
        }
    ]
}
