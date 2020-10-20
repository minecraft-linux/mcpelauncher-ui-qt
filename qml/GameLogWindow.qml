import QtQuick 2.4

import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.2
import "ThemedControls"
import io.mrarm.mcpelauncher 1.0

Window {

    property GameLauncher launcher

    id: gameLogWindow
    width: 500
    height: 400
    minimumWidth: 500
    minimumHeight: 400
    title: qsTr("Game Log")

    ColumnLayout {
        id: layout
        anchors.fill: parent
        spacing: 0

        Image {
            id: title
            smooth: false
            fillMode: Image.Tile
            source: "qrc:/Resources/noise.png"
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            Layout.preferredHeight: 50


            Text {
                anchors.fill: parent
                anchors.leftMargin: 20
                color: "#ffffff"
                text: gameLogWindow.title
                font.pixelSize: 24
                verticalAlignment: Text.AlignVCenter
            }

            MButton {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 20
                implicitWidth: 36
                implicitHeight: 36
                onClicked: { gameLog.selectAll(); gameLog.copy(); gameLog.deselect() }
                Image {
                    anchors.centerIn: parent
                    source: "qrc:/Resources/icon-copy.png"
                    smooth: false
                }
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
                    text: qsTr("It seems that Minecraft or the Launcher has crashed")
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
                    visible: !launcherSettings.disableGameLog && !launcherSettings.showUnsupported
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
            }
        }

        ScrollView {
            id: logScrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            clip: true

            function scrollToBottom() {
                ScrollBar.vertical.position = 1 - ScrollBar.vertical.size
            }


            TextEdit {
                id: gameLog
                x: 8
                y: 8
                width: logScrollView.availableWidth - 8 * 2
                wrapMode: Text.Wrap
                selectByMouse: true
                readOnly: true
                selectionColor: "#f57c00"
                text: "Hello World\nTests\nfdffsd\nsddfggrg()"

                onTextChanged: {
                    logScrollView.scrollToBottom()
                    if (launcher.crashed && !launcherSettings.disableGameLog && !launcherSettings.showUnsupported)
                        tpanel.text = "The Launcher has exited with a non-zero error code.<br><a href=\"https://github.com/ChristopherHX/mcpelauncher-manifest/issues/new?title=Launcher%20Crashed&body=Did%20older%20Launcher%20Versions%20work%20on%20this%20PC?%0A```%0A" + encodeURIComponent(gameLog.text).replace(/'/g, "%27") + "%0A```%0A%23%20Disclaimer%0AIf%20you%20don%27t%20answer%20these%20questions%20your%20issue%20will%20be%20closed\">Please click here if you would like to open an issue.</a>" 
                }
            }

            onWidthChanged: scrollToBottom()
            onHeightChanged: scrollToBottom()
        }

    }

    Connections {
        target: launcher
        onLogCleared: gameLog.clear()
        onLogAppended: gameLog.insert(gameLog.length, text)
    }

}
