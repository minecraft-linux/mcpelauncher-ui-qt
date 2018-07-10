import QtQuick 2.4

import QtQuick.Controls 1.4
import QtQuick.Layouts 1.2
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.3
import QtQuick.Controls.Styles 1.4
import "ThemedControls"
import io.mrarm.mcpelauncher 1.0

Window {

    width: 500
    height: layout.implicitHeight
    flags: Qt.Dialog
    title: "Launcher Settings"

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
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                color: "#ffffff"
                text: qsTr("Launcher Settings")
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
            rowSpacing: 8

            property int labelFontSize: 12

            Text {
                text: "Google Account"
                font.pointSize: parent.labelFontSize
            }
            Item {
                id: item1
                Layout.fillWidth: true
                height: childrenRect.height

                RowLayout {
                    anchors.right: parent.right
                    spacing: 20
                    Text {
                        text: googleLoginHelper.account !== null ? googleLoginHelper.account.accountIdentifier : ""
                        id: googleAccountIdLabel
                        Layout.alignment: Qt.AlignRight
                        font.pointSize: 11
                    }
                    MButton {
                        Layout.alignment: Qt.AlignRight
                        text: googleLoginHelper.account !== null ? "Sign out" : "Sign in"
                        onClicked: {
                            if (googleLoginHelper.account !== null)
                                googleLoginHelper.signOut()
                            else
                                googleLoginHelper.acquireAccount(window)
                        }
                    }
                }
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
                    onClicked:  close()
                }

            }

        }

    }

}
