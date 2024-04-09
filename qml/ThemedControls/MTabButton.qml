import QtQuick
import QtQuick.Templates as T

T.TabButton {
    id: control
    padding: 15
    implicitWidth: 15 + implicitContentWidth + leftPadding + rightPadding
    implicitHeight: 40
    anchors.bottom: parent.bottom

    indicator: Rectangle {
        color: "#9c6"
        width: 30
        height: 3
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        visible: checked
    }

    contentItem: Text {
        text: control.text
        font.pointSize: 11
        font.bold: checked
        opacity: enabled ? (checked ? 1.0 : hovered ? 0.9 : 0.7) : 0.3
        color: "#fff"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
