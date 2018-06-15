import QtQuick 2.0

Rectangle {
    default property alias content: container.data
    property real minWidth: 500
    property real xPadding: 5
    property real yPadding: 20

    id: rectangle
    x: parent.width / 2 - width / 2
    y: parent.height / 2 - height / 2
    width: Math.min(minWidth, parent.width)
    height: childrenRect.height + yPadding * 2

    Item {
        id: container
        x: rectangle.xPadding
        y: rectangle.yPadding
        width: parent.width - rectangle.xPadding * 2
        height: childrenRect.height
    }

}
