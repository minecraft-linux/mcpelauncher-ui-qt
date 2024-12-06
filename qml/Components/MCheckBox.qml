import QtQuick
import QtQuick.Templates as T

T.CheckBox {
    id: control
    padding: 8
    implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
    implicitHeight: Math.max(contentItem.implicitHeight, indicator.implicitHeight)
    font.pointSize: 10

    indicator: Rectangle {
        implicitWidth: 18
        implicitHeight: 18
        anchors.verticalCenter: parent.verticalCenter
        radius: 2
        color: control.checked ? (control.hovered ? "#373" : "#383") : "#1e1e1e"
        border.color: control.down ? "#888" : (control.hovered ? "#666" : "#555")

        Canvas {
            anchors.centerIn: parent
            width: 10
            height: 10
            visible: control.checked
            onPaint: {
                var ctx = getContext("2d")
                ctx.lineWidth = 2
                ctx.strokeStyle = "#fff"
                ctx.moveTo(0, height / 1.6)
                ctx.lineTo(width / 2.5, height)
                ctx.lineTo(width, 0)
                ctx.stroke()
            }
        }

        FocusBorder {
            visible: control.visualFocus
        }
    }

    contentItem: Text {
        id: textItem
        text: control.text
        font: parent.font
        opacity: enabled ? 1.0 : 0.3
        color: "#fff"
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        leftPadding: implicitIndicatorWidth + 5
    }
}
