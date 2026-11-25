import QtQuick
import QtQuick.Window
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.folderlistmodel
import "."
import io.mrarm.mcpelauncher 1.0

MessageDialog {
    id: playDownloader
    title: qsTr("Download failed")

    property var playApi: null
    property var versionManager: null
    property var launcherSettings: null
    property var progressBar: null
    property var playDownloadTask: GoogleApkDownloadTask {
        playApi: playDownloader.playApi
        packageName: playDownloader.launcherSettings.trialMode ? "com.mojang.minecrafttrialpe" : "com.mojang.minecraftpe"
        keepApks: playDownloader.launcherSettings.downloadOnly || playDownloader.launcherSettings.keepApks
        onProgress: {
            playDownloader.progressBar.value = progress
        }
        onError: function (err) {
            if (playDownloader.visible) {
                playDownloader.text += "\n" + err
            } else {
                playDownloader.text = err
                playDownloader.open()
            }
        }
        onFinished: {
            if (!playDownloader.launcherSettings.downloadOnly) {
                playDownloader.apkExtractionTask.sources = filePaths
                playDownloader.apkExtractionTask.start()
            }
        }
    }

    property var apkExtractionTask: ApkExtractionTask {
        versionManager: playDownloader.versionManager
        onProgress: {
            playDownloader.progressBar.value = progress
        }
        allowIncompatible: playDownloader.launcherSettings.showUnsupported
        onError: function (err) {
            playDownloader.text = qsTr("Error while extracting the downloaded file(s), <a href=\"https://github.com/minecraft-linux/mcpelauncher-ui-manifest/issues\">please report this error</a>: %1").arg(err)
            playDownloader.open()
        }
        onFinished: launchGame()
        allowedPackages: {
            var packages = ["com.mojang.minecrafttrialpe", "com.mojang.minecraftedu"]
            if (!playDownloader.launcherSettings.trialMode)
                packages.push("com.mojang.minecraftpe")
            return packages
        }
    }

    property var active: playDownloader.playDownloadTask.active || playDownloader.apkExtractionTask.active
    property var label: {
        if (playDownloader.playDownloadTask.active)
            return qsTr("Downloading Minecraft...")
        if (playDownloader.apkExtractionTask.active)
            return qsTr("Extracting Minecraft...")
        return ""
    }
}