import QtQuick 2.4

import QtQuick.Controls 1.4
import QtQuick.Layouts 1.11
import QtQuick.Window 2.2
import QtQuick.Controls.Styles 1.4
import "ThemedControls"

Window {

    width: 500
    height: layout.implicitHeight
    flags: Qt.Dialog
    title: "Edit profile"

    ColumnLayout {
        id: layout
        anchors.fill: parent
        spacing: 20

        Image {
            id: title
            smooth: false
            fillMode: Image.Tile
            source: "Resources/noise.png"
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            Layout.preferredHeight: 50

            Text {
                anchors.fill: parent
                anchors.margins: { left: 20; right: 20 }
                color: "#ffffff"
                text: qsTr("Edit profile")
                font.pixelSize: 24
                verticalAlignment: Text.AlignVCenter
            }

        }

        GridLayout {
            columns: 2
            Layout.fillWidth: true
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            columnSpacing: 20

            Text {
                text: "Profile Name"
                font.pixelSize: 13
            }
            MTextField {
                Layout.fillWidth: true
            }

            Text {
                text: "Version"
                font.pixelSize: 13
            }
            MTextField {
                Layout.fillWidth: true
            }

            Text {
                text: "Arguments"
                font.pixelSize: 13
            }
            MTextField {
                Layout.fillWidth: true
            }

            Text {
                text: "Data directory"
                font.pixelSize: 13
            }
            MTextField {
                Layout.fillWidth: true
            }
        }

        Image {
            id: buttons
            smooth: false
            fillMode: Image.Tile
            source: "Resources/noise.png"
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            Layout.preferredHeight: 50

            RowLayout {
                x: parent.width / 2 - width / 2
                y: parent.height / 2 - height / 2

                spacing: 20

                PlayButton {
                    Layout.preferredWidth: 150
                    text: "Save"
                }

                PlayButton {
                    Layout.preferredWidth: 150
                    text: "Cancel"
                }

            }

        }

    }

}
