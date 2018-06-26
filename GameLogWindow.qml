import QtQuick 2.4

import QtQuick.Controls 1.4
import QtQuick.Layouts 1.11
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.3
import QtQuick.Controls.Styles 1.4
import "ThemedControls"
import io.mrarm.mcpelauncher 1.0

Window {

    property GameLauncher launcher

    id: gameLogWindow
    width: 500
    height: 400
    flags: Qt.Dialog
    title: "Game Log"

    ColumnLayout {
        id: layout
        anchors.fill: parent
        spacing: 0

        Image {
            id: title
            smooth: false
            fillMode: Image.Tile
            source: "Resources/noise.png"
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            Layout.preferredHeight: 50

            Text {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                color: "#ffffff"
                text: gameLogWindow.title
                font.pixelSize: 24
                verticalAlignment: Text.AlignVCenter
            }
        }

        Rectangle {
            property int horizontalPadding: 20
            property int verticalPadding: 10

            id: rectangle
            color: "#ffbb84"
            Layout.fillWidth: true
            Layout.preferredHeight: children[0].height + verticalPadding * 2
            Layout.alignment: Qt.AlignTop
            visible: launcher.crashed

            ColumnLayout {
                x: rectangle.horizontalPadding
                y: rectangle.verticalPadding
                width: parent.width - rectangle.horizontalPadding * 2

                Text {
                    text: "It seems that Minecraft has crashed"
                    Layout.fillWidth: true
                    font.weight: Font.Bold
                    wrapMode: Text.WordWrap
                }
                Text {
                    text: "Minecraft has exited with a non-zero error code.<br><a href=\"https://github.com/minecraft-linux/mcpelauncher-manifest/issues\">Please click here if you would like to open an issue.</a>"
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    linkColor: "#593b00"
                    onLinkActivated: Qt.openUrlExternally(link)
                }
            }
        }

        ScrollView {
            id: logScrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            verticalScrollBarPolicy: Qt.ScrollBarAlwaysOff
            flickableItem.leftMargin: 8
            flickableItem.rightMargin: 8
            flickableItem.topMargin: 8
            flickableItem.bottomMargin: 8

            function scrollToBottom() {
                logScrollView.flickableItem.contentY = Math.max(logScrollView.flickableItem.contentHeight - logScrollView.height, 0)
            }

            Text {
                id: gameLog
                width: logScrollView.viewport.width - logScrollView.flickableItem.leftMargin - logScrollView.flickableItem.rightMargin
                text: launcher.log
                wrapMode: Text.WordWrap


                onTextChanged: logScrollView.scrollToBottom()
            }

            onWidthChanged: scrollToBottom()
            onHeightChanged: scrollToBottom()
        }

    }

}
