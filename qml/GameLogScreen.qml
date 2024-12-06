import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import "Components"
import io.mrarm.mcpelauncher 1.0

ColumnLayout {
    id: layout
    anchors.fill: parent
    spacing: 0
    property var launcher: null

    BaseHeader {
        title: qsTr("Game Log")
        MButton {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 10
            height: 34
            width: 34
            onClicked: {
                var text = ""
                for (var i = 0; i < gameLog.count; i++) {
                    text += gameLog.get(i).display + "\n"
                }

                launcherSettings.clipboard = text
            }
            Image {
                height: 18
                width: 18
                anchors.centerIn: parent
                source: "qrc:/Resources/icon-copy.png"
                smooth: false
            }
        }
    }

    Rectangle {
        property int horizontalPadding: 20
        property int verticalPadding: 10
        z: 2

        id: rectangle
        color: "#ffbb84"
        Layout.fillWidth: true
        Layout.preferredHeight: children[0].implicitHeight + verticalPadding * 2
        Layout.alignment: Qt.AlignTop
        visible: launcher.crashed

        ColumnLayout {
            x: rectangle.horizontalPadding
            y: rectangle.verticalPadding
            width: parent.width - rectangle.horizontalPadding * 2

            Text {
                text: qsTr("Minecraft stopped working")
                Layout.fillWidth: true
                font.weight: Font.Bold
                wrapMode: Text.WordWrap
            }
            Text {
                id: tpanel
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                linkColor: "#593b00"
                onLinkActivated: Qt.openUrlExternally(link)
                visible: !launcherSettings.disableGameLog && !launcherSettings.showUnsupported && !launcherSettings.showUnverified && !launcherSettings.showBetaVersions
            }
            Text {
                text: qsTr("Please don't report this error. Reenable Gamelog in Settings and reopen the Game to report an error")
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                visible: launcherSettings.disableGameLog
            }
            Text {
                text: qsTr("Please don't report this error. Disable show incompatible Versions and reopen the Game to report an error, because you may ran an incompatible version")
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                visible: launcherSettings.showUnsupported
            }
            Text {
                text: qsTr("Please don't report this error. Disable show unverified Versions and reopen the Game to report an error, because you may ran an incompatible version")
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                visible: launcherSettings.showUnverified
            }
            Text {
                text: qsTr("Please don't report this error. Disable show beta Versions and reopen the Game to report an error, because you may ran an incompatible version")
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                visible: launcherSettings.showBetaVersions
            }

            MouseArea {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
            }
        }
    }

    ListView {
        Layout.fillHeight: true
        Layout.fillWidth: true
        id: view
        model: gameLog
        delegate: TextArea {
            id: delegateRoot
            padding: 0
            width: ListView.view.width
            wrapMode: Text.Wrap
            text: display
            selectByMouse: false
            selectByKeyboard: false
            property int myIndex: index
            color: "#ddd"
            selectionColor: "#842"
            font.family: "monospace"

            Connections {
                target: selectionArea
                onSelectionChanged: {
                    updateSelection()
                }
            }

            Component.onCompleted: updateSelection()

            function updateSelection() {
                var keep = selectionArea.selStartIndex <= selectionArea.selEndIndex
                var selStartIndex = keep ? selectionArea.selStartIndex : selectionArea.selEndIndex
                var selStartPos = keep ? selectionArea.selStartPos : selectionArea.selEndPos
                var selEndIndex = keep ? selectionArea.selEndIndex : selectionArea.selStartIndex
                var selEndPos = keep ? selectionArea.selEndPos : selectionArea.selStartPos
                if (index < selStartIndex || index > selEndIndex) {
                    delegateRoot.select(0, 0)
                } else if (index > selStartIndex && index < selEndIndex) {
                    delegateRoot.selectAll()
                } else if (index === selStartIndex && index === selEndIndex) {
                    delegateRoot.select(selStartPos, selEndPos)
                } else if (index === selStartIndex) {
                    delegateRoot.select(selStartPos, delegateRoot.length)
                } else if (index === selEndIndex) {
                    delegateRoot.select(0, selEndPos)
                }
            }
        }
        ScrollBar.vertical: ScrollBar {
            id: scrollBar
            policy: ScrollBar.AlwaysOn
            minimumSize: 0.1
            clip: false
        }
        clip: false
        function indexAtRelative(x, y) {
            return indexAt(x + contentX, y + contentY)
        }

        Timer {
            property int offset
            id: moveToBottom
            interval: 100
            repeat: false
            running: true
            onTriggered: {
                view.ScrollBar.vertical.position = 1 - view.ScrollBar.vertical.size
                selectionArea.changePos()
            }
        }

        Connections {
            target: launcher
            onLogAppended: {
                if (view.ScrollBar.vertical.position + view.ScrollBar.vertical.size >= 1) {
                    console.log("bottom")
                    moveToBottom.running = true
                }
            }
        }

        Shortcut {
            sequence: StandardKey.Copy
            onActivated: {
                var keep = selectionArea.selStartIndex <= selectionArea.selEndIndex
                var selStartIndex = keep ? selectionArea.selStartIndex : selectionArea.selEndIndex
                var selStartPos = keep ? selectionArea.selStartPos : selectionArea.selEndPos
                var selEndIndex = keep ? selectionArea.selEndIndex : selectionArea.selStartIndex
                var selEndPos = keep ? selectionArea.selEndPos : selectionArea.selStartPos
                var text = ""
                if (selStartIndex < gameLog.count) {
                    text += gameLog.get(selStartIndex).display.substring(selStartPos)
                }
                for (var i = selStartIndex + 1; i < gameLog.count && (i + 1) < selEndIndex; i++) {
                    text += gameLog.get(i).display + "\n"
                }
                if (selEndIndex < gameLog.count) {
                    text += gameLog.get(selEndIndex).display.substring(0, selEndPos)
                }

                launcherSettings.clipboard = text
            }
        }

        Shortcut {
            sequence: StandardKey.SelectAll
            onActivated: {
                selectionArea.selStartPos = 0
                selectionArea.selStartIndex = 0
                selectionArea.selEndIndex = gameLog.count - 1
                selectionArea.selEndPos = gameLog.get(gameLog.count - 1).display.length
                selectionArea.selectionChanged()
            }
        }

        MouseArea {
            anchors.bottom: view.bottom
            anchors.left: view.left
            anchors.right: view.right
            anchors.top: view.top
            cursorShape: Qt.IBeamCursor
            id: selectionArea
            property int selStartIndex
            property int selEndIndex
            property int selStartPos
            property int selEndPos

            signal selectionChanged

            onPressed: {
                console.log("pressed " + mouseX + "-" + mouseY)
                var y = mouseY + view.contentY
                selStartIndex = view.indexAt(mouseX, y)
                var item = view.itemAtIndex(selStartIndex)
                if (item) {
                    selStartPos = item.positionAt(mouseX - item.x, y - item.y)
                }
                selEndIndex = selStartIndex
                selEndPos = selStartPos
                selectionChanged()
            }

            function changePos() {
                if (!pressed) {
                    preventStealing = false
                    return
                }
                preventStealing = true
                var y = mouseY + view.contentY
                var offset = mouseY > height ? 1 : mouseY < 0 ? -1 : 0
                if (offset < 0) {
                    y = view.contentY
                    offset *= -mouseY
                }
                if (offset > 0) {
                    var lastVisible = view.visibleChildren[view.visibleChildren.length - 1]
                    y = view.contentY + lastVisible.y + lastVisible.height - 1
                    offset *= mouseY - height
                }

                selEndIndex = view.indexAt(mouseX, y)

                var item = view.itemAtIndex(selEndIndex)
                if (item) {
                    selEndPos = item.positionAt(mouseX - item.x, y - item.y)
                }
                console.log(JSON.stringify({
                                               "selStartIndex": selStartIndex,
                                               "selStartPos": selStartPos,
                                               "selEndIndex": selEndIndex,
                                               "selEndPos": selEndPos
                                           }))
                timer.offset = offset
                timer.running = offset !== 0

                selectionChanged()
            }

            onPositionChanged: changePos()

            Timer {
                property int offset
                id: timer
                interval: 100
                repeat: true
                running: false
                onTriggered: {
                    if (!selectionArea.pressed) {
                        selectionArea.preventStealing = false
                        running = false
                        return
                    }

                    if (offset > 0 && view.ScrollBar.vertical.position + view.ScrollBar.vertical.size >= 1) {
                        view.ScrollBar.vertical.position = 1 - view.ScrollBar.vertical.size
                        running = false
                        return
                    }
                    if (offset < 0 && view.ScrollBar.vertical.position <= 0) {
                        view.ScrollBar.vertical.position = 0
                        running = false
                        return
                    }

                    view.contentY = view.contentY + offset
                    selectionArea.changePos()
                }
            }
        }
    }
}
