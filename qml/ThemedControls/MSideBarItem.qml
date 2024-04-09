import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

T.Button {
    id: control
    property alias iconSource: icon.source
    property alias showText: text.visible

    implicitHeight: 50
    implicitWidth: implicitContentWidth

    background: Rectangle {
        color: "#eee"
        width: 3
        height: 20
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        visible: control.checked
    }

    contentItem: RowLayout {
        opacity: (control.hovered && !control.checked) ? 0.85 : 1
        height: control.height

        Image {
            id: icon
            width: 30
            source: iconSource
            smooth: false
            fillMode: Image.PreserveAspectFit
            Layout.leftMargin: 18
            Layout.rightMargin: 18
        }

        Text {
            id: text
            color: "#fff"
            text: control.text
            font.pointSize: 11
            font.bold: checked
            verticalAlignment: Text.AlignVCenter
            Layout.fillHeight: true
            Layout.rightMargin: 40
        }
    }
}
