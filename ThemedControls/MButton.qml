import QtQuick 2.0
import QtQuick.Controls 2.2
import QtQuick.Templates 2.1 as T
import QtQuick.Window 2.3

T.Button {
    id: control

    padding: 8
    implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
    implicitHeight: 36
    baselineOffset: contentItem.y + contentItem.baselineOffset

    background: BorderImage {
        id: buttonBackground
        anchors.fill: parent
        source: control.hovered ? "../Resources/button-active.png" : "../Resources/button.png"
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
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
    }
}
