import QtQuick
import QtQuick.Templates as T

T.Button {
    id: control

    property color textColor: "#fff"

    padding: 8
    implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
    implicitHeight: contentItem.implicitHeight + topPadding + bottomPadding
    baselineOffset: contentItem.y + contentItem.baselineOffset

    background: Rectangle {
        id: buttonBackground
        color: control.hovered && !control.down ? "#09FFFFFF" : "#00FFFFFF"
        FocusBorder {
            visible: control.visualFocus
        }
    }

    contentItem: Text {
        id: textItem
        text: control.text
        font: control.font
        opacity: enabled ? 1.0 : 0.3
        color: textColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        topPadding: control.padding / 2
    }
}
