import QtQuick
import QtQuick.Controls
import QtQuick.Templates as T
import QtQuick.Window

T.CheckBox {
    id: control

    padding: 8
    implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
    implicitHeight: Math.max(contentItem.implicitHeight, indicator.implicitHeight)
    baselineOffset: contentItem.y + contentItem.baselineOffset
    font.pointSize: 11

    indicator: Item {
        y: parent.height / 2 - height / 2
        implicitWidth: 26
        implicitHeight: 26

        BorderImage {
            id: buttonBackground
            anchors.fill: parent
            source: control.hovered ? "qrc:/Resources/button-active.png" : "qrc:/Resources/button.png"
            smooth: false
            border { left: 4; top: 4; right: 4; bottom: 4 }
            horizontalTileMode: BorderImage.Stretch
            verticalTileMode: BorderImage.Stretch
        }
        Image {
            anchors.centerIn: parent
            id: check
            source: "qrc:/Resources/check.png"
            smooth: false
            visible: control.checked
            opacity: enabled ? 1.0 : 0.3
        }
    }

    contentItem: Text {
        id: textItem
        text: control.text
        font: control.font
        opacity: enabled ? 1.0 : 0.3
        color: "#000"
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        leftPadding: control.indicator.width
    }
}
