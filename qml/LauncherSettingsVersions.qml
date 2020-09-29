import QtQuick 2.0

import QtQuick.Layouts 1.2
import QtQuick.Controls 2.2
import "ThemedControls"

ColumnLayout {

    RowLayout {

        MButton {
            text: "Delete selected"
            onClicked: {
                if (versions.currentIndex == -1)
                    return;
                versionManager.removeVersion(versions.model[versions.currentIndex])
            }
        }

        MButton {
            text: "Import .apk"
            onClicked: apkImportWindow.pickFile()
        }

        Item {
            Layout.fillWidth: true
        }

    }

    BorderImage {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.rightMargin: 20
        source: "qrc:/Resources/dropdown-bg.png"
        smooth: false
        border { left: 4; top: 4; right: 4; bottom: 4 }
        horizontalTileMode: BorderImage.Stretch
        verticalTileMode: BorderImage.Stretch

        ListView {
            id: versions
            anchors.fill: parent
            anchors.margins: 4
            clip: true
            flickableDirection: Flickable.VerticalFlick
            model: versionManager.versions.getAll().sort(function(a, b) { return b.versionCode - a.versionCode; })
            delegate: ItemDelegate {
                id: control
                width: parent.width - 8
                height: 32
                font.pointSize: 11
                text: modelData.versionName + " (" + modelData.archs.join(", ") + ")"
                onClicked: versions.currentIndex = index
                highlighted: ListView.isCurrentItem
                background: Rectangle {
                    color: control.highlighted ? "#C5CAE9" : (control.down ? "#dddedf" : "transparent")
                }
            }
            highlightResizeVelocity: -1
            highlightMoveVelocity: -1
            currentIndex: -1
            ScrollBar.vertical: ScrollBar {}
        }
    }

    ApkImportWindow {
        id: apkImportWindow
        versionManager: versionManagerInstance
        allowIncompatible: launcherSettings.showUnsupported
    }

}
