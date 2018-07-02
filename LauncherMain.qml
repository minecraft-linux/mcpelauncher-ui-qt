import QtQuick 2.9
import QtQuick.Layouts 1.11
import QtQuick.Controls 2.4
import "ThemedControls"
import io.mrarm.mcpelauncher 1.0

ColumnLayout {

    property GoogleLoginHelper googleLoginHelper
    property VersionManager versionManager
    property ProfileManager profileManager

    id: rowLayout
    spacing: 0

    Image {
        id: title
        smooth: false
        fillMode: Image.Tile
        source: "Resources/noise.png"
        Layout.alignment: Qt.AlignTop
        Layout.fillWidth: true
        Layout.preferredHeight: 100

        RowLayout {
            anchors.fill: parent

            ColumnLayout {

                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                Image {
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    source: "Resources/proprietary/minecraft.svg"
                }

                Text {
                    color: "#ffffff"
                    text: qsTr("Unofficial Linux Launcher")
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    font.pixelSize: 16
                }

            }

        }


        MButton {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 20
            implicitWidth: 48
            implicitHeight: 48
            onClicked: launcherSettingsWindow.show()
            Image {
                anchors.centerIn: parent
                source: "Resources/icon-settings.png"
                smooth: false
            }
        }

    }

    MinecraftNews {}

    Rectangle {
        Layout.alignment: Qt.AlignBottom
        Layout.fillWidth: true
        Layout.preferredHeight: childrenRect.height + 2 * 5
        color: "#fff"
        visible: playDownloadTask.active || apkExtractionTask.active

        Item {
            y: 5
            x: parent.width / 10
            width: parent.width * 8 / 10
            height: childrenRect.height

            MProgressBar {
                id: downloadProgress
                width: parent.width
            }

            Label {
                id: downloadStatus
                width: parent.width
                height: parent.height
                text: {
                    if (playDownloadTask.active)
                        return "Downloading Minecraft..."
                    if (apkExtractionTask.active)
                        return "Extracting Minecraft..."
                    return "Please wait..."
                }
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

        }
    }

    Image {
        id: bottomPanel
        smooth: false
        fillMode: Image.Tile
        source: "Resources/noise.png"
        horizontalAlignment: Image.AlignBottom
        Layout.alignment: Qt.AlignBottom
        Layout.fillWidth: true
        Layout.preferredHeight: 100

        RowLayout {
            anchors.fill: parent

            ColumnLayout {
                Layout.leftMargin: 20

                Text {
                    text: "Profile"
                    color: "#fff"
                    font.pointSize: 10
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter

                    ProfileComboBox {
                        property bool loaded: false

                        id: profileComboBox
                        Layout.preferredWidth: 200
                        onAddProfileSelected: {
                            profileEditWindow.reset()
                            profileEditWindow.show()
                        }
                        Component.onCompleted: {
                            setProfile(profileManager.activeProfile)
                            loaded = true
                        }
                        onCurrentProfileChanged: {
                            if (loaded && currentProfile !== null)
                                profileManager.activeProfile = currentProfile
                        }
                    }

                    MButton {
                        implicitWidth: 36
                        Image {
                            anchors.centerIn: parent
                            source: "Resources/icon-edit.png"
                            smooth: false
                        }

                        onClicked: {
                            profileEditWindow.setProfile(profileComboBox.getProfile())
                            profileEditWindow.show()
                        }
                    }

                }

            }

            PlayButton {
                Layout.alignment: Qt.AlignHCenter
                text: (!versionManager.versions.contains(playVerChannel.latestVersionCode) ? "Download and play" : "Play").toUpperCase()
                subText: ("Minecraft " + playVerChannel.latestVersion).toUpperCase()
                Layout.maximumWidth: 400
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                Layout.leftMargin: width / 6
                Layout.rightMargin: width / 6
                onClicked: {
                    if (!versionManager.versions.contains(playVerChannel.latestVersionCode)) {
                        downloadProgress.value = 0
                        playDownloadTask.versionCode = playVerChannel.latestVersionCode
                        playDownloadTask.start()
                        return;
                    }
                    gameLauncher.profile = profileManager.activeProfile
                    gameLauncher.gameDir = versionManager.getDirectoryFor(versionManager.versions.get((playVerChannel.latestVersionCode)))
                    console.log("Game dir = " + gameLauncher.gameDir)
                    gameLauncher.start()
                    gameLogWindow.show()
                }
            }

        }

    }

    GooglePlayApi {
        id: playApi
        login: googleLoginHelper

        onAppInfoReceived: function(pkg, versionStr, versionCode) {
            console.log("Got app info " + versionStr + " " + versionCode)
        }

        onTosApprovalRequired: function(tos, marketing) {
            googleTosApprovalWindow.tosText = tos
            googleTosApprovalWindow.marketingText = marketing
            googleTosApprovalWindow.show()
        }
    }

    GoogleVersionChannel {
        id: playVerChannel
        playApi: playApi
    }

    GoogleApkDownloadTask {
        id: playDownloadTask
        playApi: playApi
        packageName: "com.mojang.minecraftpe"
        onProgress: downloadProgress.value = progress
        onError: console.log("Download failed: " + err)
        onFinished: {
            apkExtractionTask.source = filePath
            apkExtractionTask.start()
        }
    }

    ApkExtractionTask {
        id: apkExtractionTask
        versionManager: rowLayout.versionManager
        onProgress: downloadProgress.value = progress
        onError: console.log("Extraction failed: " + err)
        onFinished: function() {
            gameLauncher.profile = profileManager.activeProfile
            gameLauncher.gameDir = versionManager.getDirectoryFor(versionManager.versions.get((playVerChannel.latestVersionCode)))
            gameLauncher.start()
        }
    }

    GoogleTosApprovalWindow {
        id: googleTosApprovalWindow

        onDone: playApi.setTosApproved(approved, marketing)
    }

    EditProfileWindow {
        id: profileEditWindow
        versionManager: versionManagerInstance
        profileManager: profileManagerInstance
        modality: Qt.WindowModal

        onClosing: {
            profileComboBox.onAddProfileResult(profileEditWindow.profile)
        }

    }

    LauncherSettingsWindow {
        id: launcherSettingsWindow
    }

    GameLogWindow {
        id: gameLogWindow
        launcher: gameLauncher
    }

    GameLauncher {
        id: gameLauncher
    }

    Connections {
        target: googleLoginHelper
        onAccountInfoChanged: {
            if (googleLoginHelper.account !== null)
                playApi.handleCheckinAndTos()
        }
    }

    Component.onCompleted: {
        playApi.handleCheckinAndTos()
    }

}
