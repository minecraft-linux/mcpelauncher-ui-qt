import QtQuick
import QtQuick.Layouts

Rectangle {
    property string title
    property alias content: container.data

    color: "#282828"
    Layout.fillWidth: true
    Layout.minimumHeight: contents.height
    z: 2

    ColumnLayout {
        id: contents
        spacing: 15

        Text {
            leftPadding: 20
            topPadding: 20
            text: title
            color: "#fff"
            font {
                bold: true
                pointSize: 12
                capitalization: Font.AllUppercase
            }
        }

        ColumnLayout {
            id: container
            Layout.fillWidth: true
        }
    }
}
