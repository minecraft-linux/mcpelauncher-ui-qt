import QtQuick 2.0
import QtQuick.Templates 2.1 as T

T.Button {
    id: control

    padding: 8
    implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
    implicitHeight: contentItem.implicitHeight + topPadding + bottomPadding
    baselineOffset: contentItem.y + contentItem.baselineOffset

    background: BorderImage {
        id: buttonBackground
        source: "../Resources/green-button.png"
        smooth: false
        border { left: 5; top: 5; right: 5; bottom: 5 }
        horizontalTileMode: BorderImage.Stretch
        verticalTileMode: BorderImage.Stretch

        Rectangle {
            id: buttonBackgroundOverlay
            anchors.fill: background
            color: "#20000000"
            opacity: 0
        }
    }

    contentItem: Text {
        id: textItem
        text: control.text
        font.pointSize: 16
        opacity: enabled ? 1.0 : 0.3
        color: "#fff"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
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
                scale: 1.1
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
