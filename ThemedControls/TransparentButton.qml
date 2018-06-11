import QtQuick 2.0
import QtQuick.Templates 2.1 as T

T.Button {
    id: control

    padding: 8
    implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
    implicitHeight: contentItem.implicitHeight + topPadding + bottomPadding
    baselineOffset: contentItem.y + contentItem.baselineOffset

    background: Rectangle {
        id: buttonBackground
        color: "#fff"
        opacity: control.hovered ? 0.3 : 0
    }

    contentItem: Text {
        id: textItem
        text: control.text

        font: control.font
        opacity: enabled ? 1.0 : 0.3
        color: "#fff"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
