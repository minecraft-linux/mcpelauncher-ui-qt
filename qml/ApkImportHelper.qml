import QtQuick 2.4

import QtQuick.Layouts 1.2
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.2
import QtQuick.Controls.Styles 1.4
import io.mrarm.mcpelauncher 1.0
import "ThemedControls"

Item {

    signal started()
    signal finished()
    signal error()

    property VersionManager versionManager
    property bool extractingApk: false
    property var progressBar: null
    property alias task: apkExtractionTask

    id: root

    FileDialog {
        id: apkPicker
        title: "Please pick the Minecraft .apk file"
        nameFilters: [ "Android package files (*.apk *.zip)", "All files (*)" ]

        onAccepted: {
            if (!apkExtractionTask.setSourceUrl(fileUrl)) {
                apkExtractionMessageDialog.text = "Invalid file URL"
                apkExtractionMessageDialog.open()
                return;
            }
            console.log("Extracting " + apkExtractionTask.source)
            extractingApk = true
            root.started()
            apkExtractionTask.start()
        }
    }

    ApkExtractionTask {
        id: apkExtractionTask
        versionManager: root.versionManager

        onProgress: function(val) {
            root.progressBar.indeterminate = false
            root.progressBar.value = val
        }

        onFinished: function() {
            root.finished()
            extractingApk = false
        }

        onError: function(err) {
            apkExtractionMessageDialog.text = "Error while extracting the file: " + err
            apkExtractionMessageDialog.open()
            extractingApk = false
            root.error()
        }
    }

    MessageDialog {
        id: apkExtractionMessageDialog
        title: "Apk extraction"
    }


    function pickFile() {
        apkPicker.open()
    }

}
