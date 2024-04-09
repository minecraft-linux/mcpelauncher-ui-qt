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
        width: control.width
        contentItem: Text {
            text: modelData
            color: "#fff"
            font.pointSize: 10
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
        highlighted: control.highlightedIndex === index
        background: Rectangle {
            anchors.fill: parent
            color: parent.hovered ? "#333" : "#1e1e1e"
            radius: 2
        }
    }

    indicator: Canvas {
        id: canvas
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 10
        width: 13
        height: 6
        contextType: "2d"

        Connections {
            target: control
            function onPressedChanged() {
                canvas.requestPaint()
            }
        }

        onPaint: {
            context.reset()
            context.lineWidth = 1.5
            context.strokeStyle = "#bbb"
            context.moveTo(0, 0)
            context.lineTo(width / 2, height)
            context.lineTo(width, 0)
            context.stroke()
        }

        opacity: control.enabled ? 1.0 : 0.3
    }

    popup: T.Popup {
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
    }
}
