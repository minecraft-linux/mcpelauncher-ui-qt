import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import "Components"
import io.mrarm.mcpelauncher 1.0

Item {
    id: root

    property GoogleLoginHelper googleLoginHelper
    property VersionManager versionManager
    property bool acquiringAccount: false
    property bool extractingApk: false

    signal finished

    Component.onCompleted: {
        launcherSettings.trialMode = false
    }

    Image {
        anchors.fill: parent
        smooth: false
        fillMode: Image.Tile
        source: "qrc:/Resources/noise.png"
    }

    Rectangle {
        width: 400
        height: container.height + 90
        anchors.centerIn: parent
        radius: 4
        visible: !extractingApk
        color: "#222"

        ColumnLayout {
            id: container
            spacing: 10
            width: parent.width - 70
            anchors.centerIn: parent

            Text {
                text: qsTr("Sign in")
                font.pointSize: 16
                font.bold: true
                color: "#fff"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Layout.fillWidth: true
            }

            Text {
                text: qsTr("To use this launcher, you must either purchase Minecraft Android or claim the free Minecraft Trial on Google Play and sign in.\nThe free Minecraft (ChromeOS) Trial Mode can be enabled after sign in inside Settings.")
                wrapMode: Text.WordWrap
                font.pointSize: 11
                color: "#fff"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true
                Layout.topMargin: 10
            }

            PlayButton {
                text: qsTr("Sign in with Google")
                Layout.fillWidth: true
                Layout.topMargin: 10
                onClicked: function () {
                    acquiringAccount = true
                    googleLoginHelper.acquireAccount(window)
                }
            }

            RowLayout {
                id: alternativeOptions
                Layout.alignment: Qt.AlignHCenter
                spacing: 15

                TransparentButton {
                    text: qsTr("Use trial .apk").toUpperCase()
                    textColor: "#0aa82f"
                    Layout.fillWidth: true
                    font.pointSize: 11
                    onClicked: apkImportHelper.pickFile()
                }

                TransparentButton {
                    text: qsTr("Get help").toUpperCase()
                    textColor: "#0aa82f"
                    Layout.fillWidth: true
                    font.pointSize: 11
                    onClicked: Qt.openUrlExternally("https://minecraft-linux.github.io")
                }
            }
        }
    }

    Rectangle {
        width: 400
        height: extractContainer.height
        visible: extractingApk
        color: "#222"

        ColumnLayout {
            id: extractContainer
            spacing: 0
            width: parent.width

            Text {
                text: qsTr("Extracting apk")
                color: "#fff"
                font.pointSize: 15
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true
                Layout.topMargin: 15
            }

            MProgressBar {
                id: apkExtractionProgressBar
                indeterminate: true
                Layout.fillWidth: true
                Layout.margins: 15
                Layout.preferredHeight: 20
            }
        }
    }

    Text {
        text: qsTr("This is an unofficial Linux launcher for the Minecraft Bedrock codebase.\nThis project is not affiliated with Minecraft, Mojang or Microsoft.")
        color: "#fff"
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        width: parent.width
        wrapMode: Text.WordWrap
        font.pointSize: 10
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    Rectangle {
        anchors.fill: parent
        color: "#000"
        opacity: 0.3
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
        trialMode: true
        onStarted: root.extractingApk = true
        onError: root.extractingApk = false
        onFinished: {
            launcherSettings.trialMode = true
            root.finished()
        }

        Connections {
            target: apkImportHelper.task
            onVersionInformationObtained: function(dir, name, code) {
                var profile = profileManagerInstance.defaultProfile
                profile.versionType = ProfileInfo.LOCKED_CODE
                profile.versionCode = code
                profile.save()
            }
        }
    }

    Connections {
        target: googleLoginHelper
        onAccountAcquireFinished: function (acc) {
            acquiringAccount = false
            if (acc)
                root.finished()
        }
    }

    Connections {
        target: window
        onClosing: {
            application.quit()
        }
    }
}
