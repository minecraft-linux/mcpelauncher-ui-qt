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
    title: qsTr("Troubleshooting")
    property GoogleLoginHelper googleLoginHelper

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
                   text: qsTr("<a href=\"%1\">Go to wiki</a>").arg(modelData.wikiUrl)
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
            }
            ScrollBar.vertical: ScrollBar {}
        }

    }


    Troubleshooter {
        id: troubleshooter
    }

    function findIssuesAndShow() {
        var qmlissues =  troubleshooter.findIssues()
        if (googleLoginHelper.hideLatest) {
            qmlissues.push({shortDesc: qsTr("I cannot select / see the latest Version of the Game?"), longDesc: googleLoginHelper.account === null ? qsTr("You need to sign in with a Google Account owning the Game") : qsTr("You need to sign in again and / or restart the launcher to fix it."), wikiUrl: ""})
        }
        if (googleLoginHelper.account === null || googleLoginHelper.getAbis(false).length === 0) {
            qmlissues.push({shortDesc: qsTr("I cannot select / see older Versions of the Game?"), longDesc: googleLoginHelper.account === null ? qsTr("You need to sign in with a Google Account owning the Game") : qsTr("You need to sign in again and / or restart the launcher and / or check your Internet connectivity to github to fix it.%1").arg(googleLoginHelper.getAbis(true).length === 0 ? qsTr("<br/>Enable \"Show incompatible Versions\" would show more, but they won't launch on your PC see the compatibility report of the TroubleShooter for more Information") : ""), wikiUrl: ""})
        }
        qmlissues.push({shortDesc: qsTr("Why is the play button disabled for some versions?"), longDesc: qsTr("This launcher doesn't use an emulator and needs a specfic Android App version<br/><Android App Compatibility Report:<br/>If you see one <b><font color=\"#00cc00\">Compatible</font></b> cpu architecture in the following list, then you should be able to use this Launcher<br/>%1").arg(googleLoginHelper.GetSupportReport()), wikiUrl: ""})

        if (qmlissues.length == 0)
            qmlissues.push({shortDesc: qsTr("No issues found"), longDesc: qsTr("No launcher installation issues were found."), wikiUrl: ""})
        issues = qmlissues
        show()
    }

}
