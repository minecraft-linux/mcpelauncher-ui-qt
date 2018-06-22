import QtQuick 2.0
import QtQuick.Templates 2.1 as T

T.TextField {
    id: control

    padding: 8
    implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
    implicitHeight: 36
    verticalAlignment: TextInput.AlignVCenter
    font.pixelSize: 13

    background: BorderImage {
        id: buttonBackground
        anchors.fill: parent
        source: "../Resources/field.png"
        smooth: false
        border { left: 4; top: 4; right: 4; bottom: 4 }
        horizontalTileMode: BorderImage.Stretch
        verticalTileMode: BorderImage.Stretch
    }
}
