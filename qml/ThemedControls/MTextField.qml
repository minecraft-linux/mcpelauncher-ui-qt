import QtQuick
import QtQuick.Templates as T

T.TextField {
    id: control

    padding: 8
    implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
    implicitHeight: 36
    verticalAlignment: TextInput.AlignVCenter
    font.pointSize: 13
    selectByMouse: true
    selectionColor: "#51a063"

    background: BorderImage {
        id: buttonBackground
        anchors.fill: parent
        source: "qrc:/Resources/field.png"
        smooth: false
        border { left: 4; top: 4; right: 4; bottom: 4 }
        horizontalTileMode: BorderImage.Stretch
        verticalTileMode: BorderImage.Stretch
    }
}
