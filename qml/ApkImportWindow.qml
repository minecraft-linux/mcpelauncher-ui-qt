import QtQuick 2.4

import QtQuick.Layouts 1.2
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.2
import QtQuick.Controls.Styles 1.4
import io.mrarm.mcpelauncher 1.0
import "ThemedControls"

Window {

    property VersionManager versionManager

    id: root
    width: 320
    height: layout.implicitHeight + layout.anchors.topMargin + layout.anchors.bottomMargin
    flags: Qt.Dialog
    title: "Minecraft .apk import"
    visible: apkImportHelper.extractingApk

    onClosing: function() {
        close.accepted = false
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        Text {
            text: "Extracting the .apk"
            Layout.fillWidth: true
        }

        MProgressBar {
            id: apkExtractionProgressBar
            width: parent.width
            Layout.fillWidth: true
        }

    }

    ApkImportHelper {
        id: apkImportHelper
        versionManager: root.versionManager
        progressBar: apkExtractionProgressBar
    }

    function pickFile() {
        apkImportHelper.pickFile()
    }

}
