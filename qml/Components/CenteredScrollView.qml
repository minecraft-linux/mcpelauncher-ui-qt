import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ScrollView {
    property alias content: item.data
    Layout.fillHeight: true
    Layout.fillWidth: true
    contentHeight: item.height + 30
    Keys.forwardTo: item.children[0]

    Component.onCompleted: {
        ScrollBar.vertical.contentItem.color = Qt.binding(function () {
            return ScrollBar.vertical.pressed ? "#ffffff" : "#bfbfbf"
        })
    }

    Item {
        id: item
        anchors.centerIn: parent
        width: Math.min(parent.width - 30, 760)
        height: childrenRect.height
    }
}
