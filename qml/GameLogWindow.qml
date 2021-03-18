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
                text: ""

                onTextChanged: {
                    logScrollView.scrollToBottom()
                    if (launcher.crashed && !launcherSettings.disableGameLog && !launcherSettings.showUnsupported && !launcherSettings.showUnverified && !launcherSettings.showBetaVersions)
                        tpanel.text = "The Launcher has exited with a non-zero error code.<br>This Launcher is instable, please retry starting the Game before open an issue. You minimally have to provide the crashlog, your Operating System name, version, CPU architecture, GPU drivers, Launcher version, you find it in Settings->About or the git commit's of your build, Game version inclusive architecture like 1.16.201.5 (x86_64), you find it in the big green Button and a guide how to reproduce your issue. Keep in mind, you have no right for support and most crash reports cannot be fixed at all. <a href=\"https://github.com/minecraft-linux/mcpelauncher-manifest/issues\">Please click here to search for existing similar issues, before open a new issue</a>" 
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
