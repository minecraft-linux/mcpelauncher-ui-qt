import QtQuick 2.9
import QtQuick.Layouts 1.11
import "ThemedControls"
import io.mrarm.mcpelauncher 1.0

ColumnLayout {

    property GoogleLoginHelper googleLoginHelper

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
                    source: "Resources/properiaty/minecraft.svg"
                }

                Text {
                    color: "#ffffff"
                    text: qsTr("Unofficial Linux Launcher")
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    font.pixelSize: 16
                }

            }

        }

    }

    MinecraftNews {}

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

                MComboBox {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 200
                    model: ["Default", "Another Profile", "Add new profile..."]
                }

            }

            PlayButton {
                Layout.alignment: Qt.AlignHCenter
                text: "PLAY"
                Layout.maximumWidth: 400
                Layout.fillWidth: true
                Layout.preferredHeight: 65
                Layout.leftMargin: width / 5
                Layout.rightMargin: width / 5
            }

        }

    }

    GooglePlayApi {
        id: playApi
        login: googleLoginHelper

        onAppInfoReceived: function(pkg, versionStr, versionCode) {
            console.log("Got app info " + versionStr + " " + versionCode)
        }

        onTosApprovalRequired: {
            // setTosApproved(true, false)
        }

        Component.onCompleted: {
            playApi.handleCheckinAndTos()
        }
    }

}
