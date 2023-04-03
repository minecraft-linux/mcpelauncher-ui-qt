import QtQuick 2.0
import QtQuick.Controls 2.2
import QtQuick.Templates 2.1 as T
import QtQuick.Window 2.3

T.TabButton {
    id: control

    padding: 8
    implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
    implicitHeight: 34
    baselineOffset: contentItem.y + contentItem.baselineOffset

    background: BorderImage {
        id: buttonBackground
        anchors.fill: parent
        source: checked ? "qrc:/Resources/button-tab-selected.png" : ((control.hovered || control.activeFocus) ? "qrc:/Resources/button-tab-active.png" : "qrc:/Resources/button-tab.png")
        smooth: false
        border { left: 4; top: 4; right: 4; bottom: 0 }
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
