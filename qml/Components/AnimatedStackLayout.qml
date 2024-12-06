import QtQuick
import QtQuick.Layouts

StackLayout {
    id: root
    property int previousIndex: 0
    property Item previousItem: children[previousIndex]
    property Item currentItem: children[currentIndex]

    Component {
        id: animator
        ParallelAnimation {
            property bool isGoingLeft
            property int offset: isGoingLeft ? parent.width : -parent.width

            NumberAnimation {
                target: previousItem
                property: "x"
                from: 0
                to: offset
                duration: 200
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: previousItem
                property: "opacity"
                to: 0
                duration: 150
            }

            NumberAnimation {
                target: currentItem
                property: "x"
                from: -offset
                to: 0
                duration: 300
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: currentItem
                property: "opacity"
                to: 1
                duration: 150
            }

            onStarted: previousItem.visible = true
            onFinished: previousItem.visible = false
        }
    }

    Component.onCompleted: previousIndex = currentIndex

    onCurrentIndexChanged: {
        previousItem = root.children[previousIndex]
        currentItem = root.children[currentIndex]

        if (previousItem && currentItem && (previousIndex !== currentIndex)) {
            var anim = animator.createObject(parent, {
                                                 "isGoingLeft": previousIndex > currentIndex
                                             })
            anim.restart()
        }

        previousIndex = currentIndex
    }
}
