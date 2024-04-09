import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Dialogs
import QtQuick.Controls
import Qt.labs.platform
import io.mrarm.mcpelauncher 1.0
import "ThemedControls"

Item {
    signal started
    signal finished
    signal error

    property VersionManager versionManager
    property bool extractingApk: false
    property var progressBar: null
    property alias task: apkExtractionTask
    property bool allowIncompatible: false

    id: root

    FileDialog {
        id: apkPicker
        title: "Please pick the Minecraft .apk file"
        nameFilters: ["Android package files (*.apk *.zip)", "All files (*)"]
        fileMode: FileDialog.OpenFiles

        onAccepted: {
            if (!apkExtractionTask.setSourceUrls(apkPicker.currentFiles)) {
                apkExtractionMessageDialog.text = "Invalid file URL"
                apkExtractionMessageDialog.open()
                return
            }
            console.log("Extracting " + apkExtractionTask.sources.join(','))
            extractingApk = true
            root.started()
            apkExtractionTask.start()
        }
    }

    ApkExtractionTask {
        id: apkExtractionTask
        versionManager: root.versionManager

        onProgress: function (val) {
            root.progressBar.indeterminate = false
            root.progressBar.value = val
        }

        onFinished: function () {
            root.finished()
            extractingApk = false
        }

        onError: function (err) {
            apkExtractionMessageDialog.text = qsTr("The specified file is not compatible with the launcher<br/>Login to Google Play with an account owning Minecraft ( Playstore ) and let the launcher download compatible versions, including previous versions of Minecraft<br/>Details:<br/>%1").arg(err)
            apkExtractionMessageDialog.open()
            extractingApk = false
            root.error()
        }

        allowIncompatible: root.allowIncompatible
    }

    MessageDialog {
        id: apkExtractionMessageDialog
        title: "Apk extraction"
    }

    function pickFile() {
        apkPicker.open()
    }
}
