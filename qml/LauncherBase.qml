import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.2
import QtQuick.Controls 2.2
import "ThemedControls"
import io.mrarm.mcpelauncher 1.0

ColumnLayout {
    default property alias content: container.data
    property alias bottomPanelContent: bottomPanel.data
    property bool hasUpdate: false
    property string updateDownloadUrl: ""
    property bool progressbarVisible: false
    property string progressbarText: ""
    property string warnMessage: ""
    property string warnUrl: ""
    property var setProgressbarValue: function(value) {
        downloadProgress.value = value
    }

    id: rowLayout
    spacing: 0

    Image {
        id: title
        smooth: false
        fillMode: Image.Tile
        source: "qrc:/Resources/noise.png"
        Layout.alignment: Qt.AlignTop
        Layout.fillWidth: true
        Layout.preferredHeight: 100

        RowLayout {
            anchors.fill: parent

            ColumnLayout {

                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                Image {
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    source: "qrc:/Resources/mcpelauncher-logo.svg"
                    sourceSize.height: 80
                    sourceSize.width: 365 // This is required for the AppImage qt5.9 to display the svg not in 80x80
                }

                Text {
                    color: "#ffffff"
                    text: qsTr("Version %1 (build %2)").arg(LAUNCHER_VERSION_NAME).arg(LAUNCHER_VERSION_CODE)
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    font.pixelSize: 10
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
                source: "qrc:/Resources/icon-settings.png"
                smooth: false
            }
        }

    }

    Rectangle {
        Layout.alignment: Qt.AlignTop
        Layout.fillWidth: true
        Layout.preferredHeight: children[0].implicitHeight + 20
        color: hasUpdate && !(progressbarVisible || updateChecker.active) ? "#BBDEFB" : "#EE0000"
        visible: hasUpdate && !(progressbarVisible || updateChecker.active) || warnMessage.length > 0

        Text {
            width: parent.width
            height: parent.height
            text: hasUpdate && !(progressbarVisible || updateChecker.active) ? qsTr("A new version of the launcher is available. Click to download the update.") : warnMessage
            color: hasUpdate && !(progressbarVisible || updateChecker.active) ? "#0D47A1" : "#FFFFFF"
            font.pointSize: 9
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: hasUpdate && !(progressbarVisible || updateChecker.active) || rowLayout.warnUrl.length > 0 ? Qt.PointingHandCursor : Qt.Pointer
            onClicked: {
                if(hasUpdate && !(progressbarVisible || updateChecker.active)) {
                    if (updateDownloadUrl.length == 0) {
                        updateCheckerConnectorBase.enabled = true
                        updateChecker.startUpdate()
                    } else {
                        Qt.openUrlExternally(updateDownloadUrl)
                    }
                } else if(rowLayout.warnUrl.length > 0) {
                    Qt.openUrlExternally(rowLayout.warnUrl)
                }
            }
        }
    }

    ColumnLayout {
        id: container
        Layout.alignment: Qt.AlignCenter
        Layout.fillWidth: true
        Layout.fillHeight: true
    }

    Rectangle {
        Layout.alignment: Qt.AlignBottom
        Layout.fillWidth: true
        Layout.preferredHeight: childrenRect.height + 2 * 5
        color: "#fff"
        visible: progressbarVisible || updateChecker.active

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
                    if (progressbarVisible)
                        return progressbarText
                    return qsTr("Please wait...")
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
        source: "qrc:/Resources/noise.png"
        horizontalAlignment: Image.AlignBottom
        Layout.alignment: Qt.AlignBottom
        Layout.fillWidth: true
        Layout.preferredHeight: 100

    }

    MessageDialog {
        id: updateError
        title: "Update Error"
    }

    Connections {
        id: updateCheckerConnectorBase
        target: updateChecker
        enabled: false
        onUpdateError: function(error) {
            updateCheckerConnectorBase.enabled = false
            updateError.text = error
            updateError.open()
        }
        onProgress: downloadProgress.value = progress
    }
    
}
