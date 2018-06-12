import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.11
import "ThemedControls"

Window {
    id: window
    visible: true
    width: 640
    height: 480
    title: qsTr("Linux Minecraft Launcher")
    flags: Qt.Dialog

    ColumnLayout {
        id: rowLayout
        spacing: 0
        anchors.fill: parent

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

        Item {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 16

            Image {
                id: newsImage
                width: parent.width
                height: parent.height
                source: "https://community-content-assets.minecraft.net/upload/6626fc3df04c455b2c0000c5c981b341-TileMassive.jpg"
                fillMode: Image.PreserveAspectFit
            }

            Rectangle {
                x: newsImage.x + newsImage.width / 2 - width / 2
                y: newsImage.height - height
                width: newsImage.paintedWidth
                height: childrenRect.height
                color: "#A0000000"

                Text {
                    font.weight: Font.Bold
                    text: "News text placeholder"
                    color: "white"
                    padding: 8
                }
            }

            MBusyIndicator {
                x: parent.width / 2 - width / 2
                y: parent.height / 2 - height / 2
                visible: newsImage.status == Image.Loading
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
    }

}
