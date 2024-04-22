import QtQuick
import QtQuick.Layouts

Rectangle {
    property string title
    property string subtitle: ""
    property alias content: container.data

    color: "#282828"
    Layout.fillWidth: true
    Layout.minimumHeight: contents.height
    z: 2

    ColumnLayout {
        id: contents
        spacing: 15

        Text {
            Layout.topMargin: 20
            Layout.leftMargin: 20
            Layout.bottomMargin: subtitle.length > 0 ? 5 : 0
            text: title
            color: "#fff"
            font {
                bold: true
                pointSize: 12
                capitalization: Font.AllUppercase
            }
            Text {
                anchors.top: parent.bottom
                anchors.left: parent.left
                text: subtitle
                font.pointSize: 8
                color: "#999"
            }
        }

        ColumnLayout {
            id: container
            Layout.fillWidth: true
        }
    }
}
