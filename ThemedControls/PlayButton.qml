import QtQuick 2.0
import QtQuick.Layouts 1.11
import QtQuick.Templates 2.1 as T

T.Button {
    id: control

    property string subText: null

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

    contentItem: Item {
        implicitWidth: childrenRect.width
        implicitHeight: content.height
        ColumnLayout {
            id: content
            spacing: 3
            width: Math.max(parent.width, Math.max(textItem.implicitWidth, subTextItem.implicitWidth))
            y: parent.height / 2 - height / 2
            Text {
                id: textItem
                text: control.text
                font.pointSize: 16
                opacity: enabled ? 1.0 : 0.3
                color: "#fff"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Layout.fillWidth: true
            }
            Text {
                id: subTextItem
                visible: control.subText != null && control.subText.length > 0
                text: control.subText
                font.pointSize: 10
                opacity: enabled ? 1.0 : 0.3
                color: "#fff"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Layout.fillWidth: true
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
