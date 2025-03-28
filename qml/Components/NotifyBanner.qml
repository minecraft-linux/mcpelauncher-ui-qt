import QtQuick
import QtQuick.Controls

Rectangle {
    id: control

    property string title: ""
    property string description: ""
    property string actionText: ""
    property bool dismissible: true
    signal clicked

    width: parent.width
    height: textColumn.implicitHeight + 30
    color: "#145"
    border.color: color.lighter(1.3)
    border.width: 2

    Row {
        x: 15
        y: 15
        width: parent.width - 30

        Column {
            id: textColumn
            width: parent.width - actionRow.width
            spacing: 4
            MText {
                width: parent.width
                text: control.title
                font.pointSize: 11
                font.bold: true
                elide: Text.ElideRight
                wrapMode: Text.Wrap
            }
            MText {
                width: parent.width
                text: control.description
                elide: Text.ElideRight
                wrapMode: Text.Wrap
            }
        }

        Row {
            id: actionRow
            y: 3
            height: 36
            property color color: control.color.lighter(3.0)
            TransparentButton {
                id: actionButton
                text: control.actionText
                textColor: (hovered && !pressed) ? "#fff" : parent.color
                background: FocusBorder {
                    anchors.fill: parent
                    visible: parent.visualFocus
                }
                font.bold: true
                font.pointSize: 10
                height: parent.height
                width: implicitContentWidth + 26
                onClicked: control.clicked()
                visible: text
                padding: 0
            }
            Rectangle {
                y: 8
                width: 2
                height: parent.height - 16
                visible: dismissButton.visible && actionButton.visible
                color: parent.color
                opacity: 0.15
                clip: false
            }
            TransparentButton {
                id: dismissButton
                text: "⨯"
                textColor: (hovered && !pressed) ? "#fff" : parent.color
                background: FocusBorder {
                    anchors.fill: parent
                    visible: parent.visualFocus
                }
                font.bold: true
                font.pointSize: 12
                visible: control.dismissible
                height: parent.height
                width: 36
                padding: 0
                onClicked: {
                    control.visible = false
                }
            }
        }
    }
}
