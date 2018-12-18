import QtQuick 2.0
import QtQuick.Layouts 1.2
import QtQuick.Dialogs 1.2
import QtQuick.Window 2.3
import "ThemedControls"
import io.mrarm.mcpelauncher 1.0

Item {
    id: root

    property GoogleLoginHelper googleLoginHelper
    property VersionManager versionManager
    property bool acquiringAccount: false
    property bool extractingApk: false

    signal finished()

    Image {
        anchors.fill: parent
        smooth: false
        fillMode: Image.Tile
        source: "qrc:/Resources/noise.png"
    }

    CenteredRectangle {
        radius: 4
        visible: !extractingApk

        ColumnLayout {
            spacing: 0
            width: parent.width

            Text {
                text: "Sign in"
                font.pointSize: 22
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true
                Layout.topMargin: 4
            }

            Text {
                text: "To use this launcher, you must purchase Minecraft on Google Play and sign in."
                wrapMode: Text.WordWrap
                font.pointSize: 12
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true
                Layout.topMargin: 16
            }

            PlayButton {
                text: "Sign in with Google"
                leftPadding: 50
                rightPadding: 50
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 22
                onClicked: function() {
                    acquiringAccount = true
                    googleLoginHelper.acquireAccount(window)
                }
            }

            RowLayout {
                id: alternativeOptions

                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 4
                spacing: 25

                property int buttonWidth: Math.max(children[0].implicitWidth, children[1].implicitWidth)

                TransparentButton {
                    text: "Use .apk".toUpperCase()
                    textColor: "#0aa82f"
                    Layout.preferredWidth: alternativeOptions.buttonWidth
                    font.pointSize: 12
                    onClicked: apkImportHelper.pickFile()
                }

                TransparentButton {
                    text: "Get help".toUpperCase()
                    textColor: "#0aa82f"
                    Layout.preferredWidth: alternativeOptions.buttonWidth
                    font.pointSize: 12
                    onClicked: Qt.openUrlExternally("https://github.com/minecraft-linux/mcpelauncher-ui-manifest/wiki")
                }

            }
        }

    }

    CenteredRectangle {
        radius: 4
        visible: extractingApk

        ColumnLayout {
            spacing: 0
            width: parent.width

            Text {
                text: "Extracting apk"
                font.pointSize: 18
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true
            }

            MProgressBar {
                id: apkExtractionProgressBar
                indeterminate: true
                Layout.preferredWidth: parent.width * 0.7
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                Layout.topMargin: 20
            }

        }

    }


    Text {
        text: "This is an unofficial Linux launcher for the Minecraft Bedrock codebase.\nThis project is not affiliated with Minecraft, Mojang or Microsoft."
        color: "#fff"
        y: parent.height - height - 10
        width: parent.width
        wrapMode: Text.WordWrap
        font.pointSize: 10
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.2
        visible: acquiringAccount

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
        }
    }

    ApkImportHelper {
        id: apkImportHelper
        progressBar: apkExtractionProgressBar
        versionManager: versionManagerInstance
        onStarted: root.extractingApk = true
        onError: root.extractingApk = false
        onFinished: root.finished()

        Connections {
            target: apkImportHelper.task
            onVersionInformationObtained: {
                var profile = profileManagerInstance.defaultProfile
                profile.versionType = ProfileInfo.LOCKED_NAME
                profile.versionDirName = directory
                profile.save()
            }
        }
    }

    Connections {
        target: googleLoginHelper
        onAccountAcquireFinished: function(acc) {
            acquiringAccount = false;
            if (acc)
                root.finished()
        }
    }

}
