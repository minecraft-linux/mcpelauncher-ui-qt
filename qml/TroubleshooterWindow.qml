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
    minimumWidth: 500
    minimumHeight: 400
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
                   text: modelData.shortDesc
                   Layout.fillWidth: true
                   font.bold: true
                   wrapMode: Text.WordWrap
               }
               Text {
                   text: modelData.longDesc
                   Layout.fillWidth: true
                   wrapMode: Text.WordWrap
                   linkColor: "#2962FF"
               }
               Text {
                   text: "<a href=\"" + modelData.wikiUrl + "\">Go to wiki</a>"
                   Layout.fillWidth: true
                   wrapMode: Text.WordWrap
                   linkColor: "#2962FF"
                   onLinkActivated: Qt.openUrlExternally(link)
                   visible: modelData.wikiUrl.length > 0
                   MouseArea {
                       anchors.fill: parent
                       cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                       acceptedButtons: Qt.NoButton
                   }
               }
               Text {
                   Layout.fillWidth: true
                   wrapMode: Text.WordWrap
                   text: "<b>Android App Compatibility Report:</b><br/>" + googleLoginHelper.GetSupportReport()
               }
               Text {
                   Layout.fillWidth: true
                   wrapMode: Text.WordWrap
                   text: "<b>I cannot select / see the latest Version of the Game?</b><br/>" + (googleLoginHelper.account === null ? "You need to sign in with a Google Account owning the Game" : "You need to sign in again and / or restart the launcher to fix it.")
                   visible: googleLoginHelper.hideLatest
               }
               Text {
                   Layout.fillWidth: true
                   wrapMode: Text.WordWrap
                   text: "<b>I cannot select / see older Versions of the Game?</b><br/>" + (googleLoginHelper.account === null ? "You need to sign in with a Google Account owning the Game" : ("You need to sign in again and / or restart the launcher and / or check your Internet connectivity to github to fix it." + (googleLoginHelper.getDeviceStateABIs(true).length === 0 ? "<br/>Enable \"Show incompatible Versions\" would show more, but they won't launch on your PC see the compatibility report of the TroubleShooter for more Information" : "")))
                   visible: googleLoginHelper.account === null || googleLoginHelper.getDeviceStateABIs(false).length === 0
               }
            }
            ScrollBar.vertical: ScrollBar {}
        }

    }


    Troubleshooter {
        id: troubleshooter
    }

    function findIssuesAndShow() {
        issues = troubleshooter.findIssues()
        if (issues.length == 0)
            issues = [{shortDesc: "No issues found", longDesc: "No launcher installation issues were found.", wikiUrl: ""}]
        show()
    }

}
