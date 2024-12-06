import QtQuick
import QtQuick.Controls
import QtQuick.Templates as T

T.ComboBox {
    id: control

    implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
    implicitHeight: 35
    leftPadding: 8
    rightPadding: 36
    opacity: control.enabled ? 1.0 : 0.3

    background: Rectangle {
        border.color: control.hovered ? "#666" : "#555"
        color: "#1e1e1e"
        FocusBorder {
            visible: control.visualFocus
        }
    }

    contentItem: Text {
        id: textItem
        text: control.displayText
        font.pointSize: 10
        color: "#fff"
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    delegate: ItemDelegate {
        width: parent.width
        contentItem: Text {
            text: control.textRole ? (Array.isArray(control.model) ? modelData[control.textRole] : model[control.textRole]) : modelData
            color: "#fff"
            font.pointSize: 10
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
        highlighted: control.highlightedIndex === index
        background: Rectangle {
            anchors.fill: parent
            color: highlighted ? "#333" : "#1e1e1e"
            radius: 2

            FocusBorder {
                visible: highlighted && control.visualFocus
            }
        }
    }

    indicator: Canvas {
        id: canvas
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 10
        opacity: control.enabled ? 1.0 : 0.3
        width: 13
        height: 6
        onPaint: {
            var ctx = getContext("2d")
            ctx.lineWidth = 1.5
            ctx.strokeStyle = "#bbb"
            ctx.moveTo(0, 0)
            ctx.lineTo(width / 2, height)
            ctx.lineTo(width, 0)
            ctx.stroke()
        }
    }

    popup: T.Popup {
        id: popupBox
        y: control.height
        width: control.width
        height: Math.min(contentItem.implicitHeight + topPadding + bottomPadding, control.Window.height - topMargin - bottomMargin)
        topMargin: 6
        bottomMargin: 6
        padding: 4

        contentItem: ListView {
            ScrollBar.vertical: ScrollBar {}
            clip: true
            implicitHeight: contentHeight
            model: control.delegateModel
            currentIndex: control.highlightedIndex
            highlightMoveDuration: 0
        }

        background: Rectangle {
            color: "#1e1e1e"
            border.color: "#555"
            radius: 2
        }

        enter: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 100
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                property: "y"
                from: 0
                to: control.height
                duration: 120
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                property: "scale"
                from: 0.97
                to: 1
                duration: 80
                easing.type: Easing.OutCubic
            }
        }

        exit: Transition {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: 80
                easing.type: Easing.OutSine
            }

            NumberAnimation {
                property: "y"
                from: control.height
                to: 0
                duration: 80
            }

            NumberAnimation {
                property: "scale"
                from: 1
                to: 0.97
                duration: 60
                easing.type: Easing.OutCubic
            }
        }
    }
}
