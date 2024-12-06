import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Dialogs
import "Components"
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
    property GoogleVersionChannel playVerChannel
    color: "#333333"

    ColumnLayout {
        id: layout
        anchors.fill: parent
        spacing: 0

        BaseHeader {
            title: troubleshooterWindow.title
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            flickableDirection: Flickable.VerticalFlick
            spacing: 15
            model: issues
            topMargin: 15
            delegate: ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 15
                spacing: 5
                HorizontalDivider {
                    visible: index > 0
                    Layout.bottomMargin: 15
                }
                Text {
                    text: modelData.shortDesc
                    Layout.fillWidth: true
                    font.bold: true
                    font.pointSize: 10
                    color: "#fff"
                    wrapMode: Text.WordWrap
                }
                Text {
                    text: modelData.longDesc
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: "#fff"
                    linkColor: "#57f"
                    font.pointSize: 10
                    onLinkActivated: Qt.openUrlExternally(link)
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                        acceptedButtons: Qt.NoButton
                    }
                }
                Text {
                    text: qsTr("<a href=\"%1\">Go to wiki</a>").arg(modelData.wikiUrl)
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: "#fff"
                    linkColor: "#57f"
                    onLinkActivated: Qt.openUrlExternally(link)
                    visible: modelData.wikiUrl.length > 0
                    font.pointSize: 10
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
        var qmlissues = troubleshooter.findIssues()
        if (googleLoginHelper.hideLatest) {
            qmlissues.push({
                               "shortDesc": qsTr("I cannot select / see the latest Version of the Game?"),
                               "longDesc": googleLoginHelper.account === null ? qsTr("You need to sign in with a Google Account owning the Game") : qsTr("You need to sign in again and / or restart the launcher to fix it."),
                               "wikiUrl": ""
                           })
        }
        if (googleLoginHelper.account === null || googleLoginHelper.getAbis(false).length === 0) {
            qmlissues.push({
                               "shortDesc": qsTr("I cannot select / see older Versions of the Game?"),
                               "longDesc": googleLoginHelper.account === null ? qsTr("You need to sign in with a Google Account owning the Game") : qsTr("You need to sign in again and / or restart the launcher and / or check your Internet connectivity to github to fix it.%1").arg(googleLoginHelper.getAbis(true).length === 0 ? qsTr("<br/>Enable \"Show incompatible Versions\" would show more, but they won't launch on your PC see the compatibility report of the TroubleShooter for more Information") : ""),
                               "wikiUrl": ""
                           })
        }
        if (!playVerChannel.latestVersionIsBeta) {
            qmlissues.push({
                               "shortDesc": qsTr("\"Show Beta Versions\" is disabled or greyed out?"),
                               "longDesc": qsTr("You need to own the game and sign up for the <a href=\"https://play.google.com/apps/testing/com.mojang.minecraftpe\">Minecraft beta program on Google Play</a>."),
                               "wikiUrl": ""
                           })
        }
        if (playApi.status < 3 /* GooglePlayApiStatus::SUCCEDED */
                ) {
            qmlissues.push({
                               "shortDesc": qsTr("Failed to initialize Google Play API"),
                               "longDesc": qsTr("Please check your internet connection and / or login to Google Play again<br/>Statuscode of playApi is %1").arg(playApi.status),
                               "wikiUrl": ""
                           })
        }
        if (playVerChannel.status < 3 /* GoogleVersionChannelStatus::SUCCEDED */
                ) {
            qmlissues.push({
                               "shortDesc": qsTr("Failed to obtain the gameversion"),
                               "longDesc": qsTr("Please check your internet connection and / or login to Google Play again<br/>Statuscode of playVerChannel is %1").arg(playVerChannel.status),
                               "wikiUrl": ""
                           })
        }
        qmlissues.push({
                           "shortDesc": qsTr("Why is the play button disabled for some versions?"),
                           "longDesc": qsTr("This launcher doesn't use an emulator and needs a specfic Android App version<br/><Android App Compatibility Report:<br/>If you see one <b><font color=\"#00cc00\">Compatible</font></b> cpu architecture in the following list, then you should be able to use this Launcher<br/>%1").arg(googleLoginHelper.GetSupportReport()),
                           "wikiUrl": ""
                       })

        if (qmlissues.length == 0)
            qmlissues.push({
                               "shortDesc": qsTr("No issues found"),
                               "longDesc": qsTr("No launcher installation issues were found."),
                               "wikiUrl": ""
                           })
        issues = qmlissues
        show()
    }
}
