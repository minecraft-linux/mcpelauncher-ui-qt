import QtQuick 2.4

import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.2
import "ThemedControls"
import io.mrarm.mcpelauncher 1.0

Window {

    property GameLauncher launcher

    property var issues: []

    id: troubleshooterWindow
    width: 500
    height: 400
    flags: Qt.Dialog
    title: "Troubleshooting"

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
                text: troubleshooterWindow.title
                font.pixelSize: 24
                verticalAlignment: Text.AlignVCenter
            }

        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            flickableDirection: Flickable.VerticalFlick
            spacing: 16
            model: issues
            topMargin: 8
            clip: true
            delegate: ColumnLayout {
               anchors.left: parent.left
               anchors.right: parent.right
               anchors.margins: 8
               spacing: 0

               Text {
                   text: modelData.name
                   Layout.fillWidth: true
                   font.bold: true
                   wrapMode: Text.WordWrap
               }
               Text {
                   text: modelData.description
                   Layout.fillWidth: true
                   wrapMode: Text.WordWrap
                   linkColor: "#2962FF"
                   onLinkActivated: Qt.openUrlExternally(link)
                   MouseArea {
                       anchors.fill: parent
                       cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                       acceptedButtons: Qt.NoButton
                   }
               }
            }
            ScrollBar.vertical: ScrollBar {}
        }

    }


    function createIssue(name, description, wikiUrl) {
        if (wikiUrl)
            description += "<br><a href=\"" + wikiUrl + "\">Go to wiki</a>"

        return {name: name, description: description}
    }

    function startTroubleshooting() {
        issues = []
        issues.push(createIssue("No CPU SSSE3 support", "Your CPU may be unsupported and the game may crash on startup.", null))
        issues.push(createIssue("Software rendering", "The game is using the software (CPU) rendering. This will negatively impact performance.", "https://github.com/minecraft-linux/mcpelauncher-manifest/wiki/Troubleshooting#graphics-performance-issues-software-rendering"))
        issues.push(createIssue("MSA daemon could not be found", "The MSA component might has not been installed properly. Xbox Live login may not work.", "https://github.com/minecraft-linux/mcpelauncher-manifest/wiki/Troubleshooting#msa-daemon-could-not-be-found"))
        return issues
    }

    Component.onCompleted: {
        issues = startTroubleshooting()
    }

}
