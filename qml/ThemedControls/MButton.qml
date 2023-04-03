import QtQuick
import QtQuick.Controls
import QtQuick.Templates as T
import QtQuick.Window

T.Button {
    id: control

    padding: 8
    implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
    implicitHeight: 36
    baselineOffset: contentItem.y + contentItem.baselineOffset

    background: BorderImage {
        id: buttonBackground
        anchors.fill: parent
        source: (control.hovered || control.activeFocus) ? "qrc:/Resources/button-active.png" : "qrc:/Resources/button.png"
        smooth: false
        border { left: 4; top: 4; right: 4; bottom: 4 }
        horizontalTileMode: BorderImage.Stretch
        verticalTileMode: BorderImage.Stretch
    }

    contentItem: Text {
        id: textItem
        text: control.text
        font.pointSize: 11
        opacity: enabled ? 1.0 : 0.3
        color: "#000"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
