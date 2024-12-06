import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ScrollView {
    property alias content: item.data
    Layout.fillHeight: true
    Layout.fillWidth: true
    contentHeight: item.height + 30
    Keys.forwardTo: item.children[0]

    //ScrollBar.vertical.palette.dark: "white"
    // ScrollBar.vertical: ScrollBar {
    //     id: control
    //     orientation: Qt.Vertical
        
    
    //     contentItem: Rectangle {
    //         implicitWidth: 6
    //         implicitHeight: 100
    //         radius: width / 2
    //         color: control.pressed ? "#81e889" : "#c2f4c6"
    //     }
    // }
    Component.onCompleted: {
        ScrollBar.vertical.contentItem.color = Qt.binding(function() { return ScrollBar.vertical.pressed ? "#ffffff" : "#bfbfbf" })
        console.log(ScrollBar.vertical.contentItem)
    }

    Item {
        id: item
        anchors.centerIn: parent
        width: Math.min(parent.width - 30, 760)
        height: data[0].height
    }
}
