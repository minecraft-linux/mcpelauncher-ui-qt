import QtQuick 2.0
import QtQuick.Templates 2.1 as T

T.Button {
    id: control

    padding: 8
    implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
    implicitHeight: contentItem.implicitHeight + topPadding + bottomPadding
    baselineOffset: contentItem.y + contentItem.baselineOffset

    background: BorderImage {
        source: "../Resources/green-button.png"
        smooth: false
        border { left: 10; top: 10; right: 10; bottom: 10; }
        horizontalTileMode: BorderImage.Stretch
        verticalTileMode: BorderImage.Stretch
    }

    contentItem: Text {
        id: textItem
        text: control.text
        font.pointSize: 16
        opacity: enabled ? 1.0 : 0.3
        color: "#fff"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
