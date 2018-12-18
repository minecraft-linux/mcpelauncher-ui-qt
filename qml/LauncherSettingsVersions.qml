import QtQuick 2.0

import QtQuick.Layouts 1.2
import QtQuick.Controls 2.2
import "ThemedControls"

ColumnLayout {

    RowLayout {

        MButton {
            text: "Delete selected"
        }

        MButton {
            text: "Import .apk"
        }

        Item {
            Layout.fillWidth: true
        }

    }

    BorderImage {
        Layout.fillWidth: true
        Layout.fillHeight: true
        source: "qrc:/Resources/dropdown-bg.png"
        smooth: false
        border { left: 4; top: 4; right: 4; bottom: 4 }
        horizontalTileMode: BorderImage.Stretch
        verticalTileMode: BorderImage.Stretch

        ListView {
            anchors.fill: parent
            anchors.margins: 4
            clip: true
            flickableDirection: Flickable.VerticalFlick
            model: versionManager.versions.getAll().sort(function(a, b) { return b.versionCode - a.versionCode; })
            delegate: ItemDelegate {
                width: parent.width
                height: 32
                font.pointSize: 11
                text: modelData.versionName
            }
            ScrollBar.vertical: ScrollBar {}
        }
    }

}
