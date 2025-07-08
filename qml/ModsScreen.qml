import QtQuick 2.9
import QtQuick.Dialogs
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.2
import io.mrarm.mcpelauncher 1.0

import "Components"

AnimatedStackLayout {
    id: stack
    property var elem: null

    function reload() {
        var s = stack
        var bck = s.elem
        s.elem = {}
        s.elem = bck
        s.currentIndex = 1
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 0
        id: list

        BaseHeader {
            Layout.fillWidth: true
            title: qsTr("Mods")
            content: TabBar {
                id: tabs
                background: null
                MTabButton {
                    text: qsTr("Mods")
                }
                MTabButton {
                    text: qsTr("Installed Mods")
                }
                MTabButton {
                    text: qsTr("FAQ")
                }
            }
        }
        
        ModManager {
            id: modManager
        }

        AnimatedStackLayout {
            id: stackLayout
            currentIndex: tabs.currentIndex
            Layout.fillWidth: true
            Layout.fillHeight: true

            ModsGrid {
                id: modsGrid
            }

            ModsGrid {
                id: installedModsGrid
                model: {
                    reload();
                }

                function reload() {
                    var ret = [];
                    const mods = modManager.listMods()
                    var modByName = {};
                    for (let i = 0; i < mods.length; ++i) {
                        modByName[mods[i].name] = mods[i].metadata.metadata || {
                            name: mods[i].name,
                            version: mods[i].version,
                            arch: mods[i].arch,
                            description: "",
                            image: "qrc:/Resources/icon-home.png"
                        };
                    }
                    installedModsGrid.model = Object.values(modByName);
                }
            }

            CenteredScrollView {
                content: ColumnLayout {
                    width: parent.width
                    spacing: 16
                    MText {
                        text: qsTr("Welcome to our experimental mods section.")
                        font.bold: true
                        font.pointSize: 12
                    }
                    TextEdit {
                        focus: true
                        Layout.fillWidth: true
                        textFormat: Text.RichText
                        wrapMode: Text.WordWrap
                        text: "<style type=\"text/css\">a { color: #6af; }</style>" + qsTr("Managing mods is not yet supported. To contribute your mod, please open a pull request on <a href=\"https://github.com/minecraft-linux/mcpelauncher-moddb\">minecraft-linux/mcpelauncher-moddb</a>.<br/><br/>Mods are a collection of .so files (also on macOS) placed inside the `mods` folder. This folder is located within your data root, which you can find in Settings > Storage. The `mods` folder does not exist by default, so you'll need to create it. Extract zip files directly into the `mods` folder without creating subfolders.  .so files should be directly below the `mods` folder.<br/><br/><font color=\"#f66\">Do not report crashes to the launcher's issue tracker when mods are enabled.</font>")
                        font.pointSize: 10
                        color: "#fff"
                        readOnly: true
                        selectByMouse: true
                        onLinkActivated: Qt.openUrlExternally(link)

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                            acceptedButtons: Qt.NoButton
                        }
                    }
                }
            }
        }

        property int articlesCount: 0
        property int articlesOffset: 0
        property int articlesPerPage: 20
        property bool articlesLoading: false

        function loadMods() {
            list.articlesLoading = true
            var offset = list.articlesOffset
            if (list.articlesCount > 0) {
                offset += list.articlesPerPage
            }
            var req = new XMLHttpRequest()
            var url = "https://github.com/minecraft-linux/mcpelauncher-moddb/raw/main/moddb.json?v=" + Math.random()

            req.open("GET", url, true)
            req.onerror = function () {
                console.log("Failed to load mods")
                list.articlesLoading = false
            }
            req.onreadystatechange = function () {
                if (req.readyState === XMLHttpRequest.DONE) {
                    if (req.status === 200) {
                        parseModsResponse(JSON.parse(req.responseText))
                        list.articlesOffset = offset
                    } else {
                        req.onerror()
                    }
                }
                list.articlesLoading = false
            }
            req.send()
        }

        function parseModsResponse(resp) {
            list.articlesCount = resp.length
            list.articlesOffset = resp.length + 1
            list.articlesPerPage = resp.length
            if (modsGrid.model === null) {
                modsGrid.model = resp
            } else {
                var model = modsGrid.model
                model.push.apply(model, resp)
                modsGrid.model = model
            }
        }

        Component.onCompleted: loadMods()
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 0

        RowLayout {
            Layout.margins: 15
            spacing: 15
            MButton {
                text: qsTr("Back")
                onClicked: {
                    stack.currentIndex = 0
                }
            }
            MText {
                font.bold: true
                font.pointSize: 17
                text: qsTr("Mods") + " / " + (stack.elem && stack.elem.name || qsTr("Untitled Mod"))
            }
        }

        CenteredScrollView {
            content: ColumnLayout {
                width: parent.width
                spacing: 10

                Image {
                    Layout.fillWidth: true
                    Layout.maximumHeight: 200
                    Layout.bottomMargin: 30
                    fillMode: Image.PreserveAspectFit
                    source: stack.elem && stack.elem.image || "qrc:/Resources/icon-home.png"
                    smooth: false
                }

                MText {
                    Layout.fillWidth: true
                    wrapMode: TextEdit.Wrap
                    text: stack.elem && stack.elem.description || ""
                }

                MText {
                    Layout.fillWidth: true
                    wrapMode: TextEdit.Wrap
                    color: "#bbb"
                    text: stack.elem && stack.elem.url || ""
                }

                TextEdit {
                    id: edit
                    focus: true
                    Layout.fillWidth: true
                    wrapMode: TextEdit.Wrap
                    text: "<style type=\"text/css\">a { color: lightblue; }</style><a href=\"" + (stack.elem && stack.elem.url && stack.elem.url.indexOf("\"") === -1 && stack.elem.url || "") + "\">Homepage</a>"
                    color: "white"
                    textFormat: Text.RichText
                    readOnly: true
                    selectByMouse: true
                    onLinkActivated: Qt.openUrlExternally(link)
                    font.pointSize: 10

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                        acceptedButtons: Qt.NoButton
                    }
                }

                ListView {
                    id: downloads
                    activeFocusOnTab: true
                    Layout.fillWidth: true
                    Layout.minimumHeight: 60 * count
                    anchors.margins: 4
                    clip: true
                    flickableDirection: Flickable.VerticalFlick
                    model: {
                        if (!stack.elem) {
                            return []
                        }
                        return stack.elem.versions
                    }
                    delegate: ItemDelegate {
                        id: control
                        width: parent.width
                        font.pointSize: 11
                        contentItem: RowLayout {
                            MText {
                                text: modelData.version
                                Layout.fillWidth: true
                            }
                            MButton {
                                text: qsTr("Download")
                                property var abis: googleLoginHelperInstance.getAbis(false)
                                property var arch: profileManagerInstance.activeProfile.arch || abis.length > 0 && abis[0]
                                visible: !modManager.modExists(stack.elem.name, modelData.version, arch)
                                enabled: (modelData.assets[arch] && modelData.assets[arch].length > 0 || false) && !progress.visible
                                onClicked: {
                                    console.log(JSON.stringify(modelData.assets))
                                    console.log(arch)
                                    modManager.saveMod(stack.elem.name, modelData.version, arch, {
                                        metadata: stack.elem,
                                        version: modelData,
                                        arch: arch
                                    })
                                    downloadTask.activemod = {
                                        name: stack.elem.name,
                                        version: modelData.version,
                                        arch: arch
                                    }

                                    download1.url = modelData.assets[arch]
                                    download1.componentName = stack.elem.name
                                    downloadTask.startDownload([download1])
                                    zipTask.targetDir = modManager.getFolderPathForMod(stack.elem.name, modelData.version, arch);
                                }
                            }
                            MButton {
                                property var prefix: modManager.getRoot() + "/" + stack.elem.name + "/"
                                property var abis: googleLoginHelperInstance.getAbis(false)
                                property var arch: profileManagerInstance.activeProfile.arch || abis.length > 0 && abis[0]
                                visible: modManager.modExists(stack.elem.name, modelData.version, arch)
                                enabled: (modelData.assets[arch] && modelData.assets[arch].length > 0 || false)
                                property var entry: prefix + modelData.version + "/" + arch + "/"
                                text: profileManagerInstance.activeProfile.mods.includes(entry) ? qsTr("Disable") : qsTr("Activate")
                                onClicked: {
                                    var has = profileManagerInstance.activeProfile.mods.includes(entry)
                                    profileManagerInstance.activeProfile.mods = profileManagerInstance.activeProfile.mods.filter(function (e) {
                                        return !e.startsWith(prefix)
                                    })
                                    if(!has) {
                                        profileManagerInstance.activeProfile.mods.push(entry)
                                    }
                                    console.log("Mods: " + JSON.stringify(profileManagerInstance.activeProfile.mods))
                                    profileManagerInstance.activeProfile.save()
                                }
                            }
                            MButton {
                                property var abis: googleLoginHelperInstance.getAbis(false)
                                property var arch: profileManagerInstance.activeProfile.arch || abis.length > 0 && abis[0]
                                visible: modManager.modExists(stack.elem.name, modelData.version, arch)
                                text: qsTr("Delete")
                                onClicked: {
                                    modManager.removeMod(stack.elem.name, modelData.version, arch)
                                    installedModsGrid.reload();
                                    stack.reload();
                                }
                            }
                        }

                        onClicked: downloads.currentIndex = index
                        highlighted: ListView.isCurrentItem
                        background: Rectangle {
                            color: control.highlighted ? "#226322" : (control.down ? "#338833" : (control.hovered ? "#222" : "transparent"))
                        }
                    }
                    highlightResizeVelocity: -1
                    highlightMoveVelocity: -1
                    currentIndex: -1
                    ScrollBar.vertical: ScrollBar {}
                }
            }
        }

        DownloadDataWrapper {
            id: download1
        }

        MessageDialog {
            id: modDownloadExtractError
        }

        DownloadTask {
            id: downloadTask
            property var activemod: null
            keepDownload: false
            onProgress: {
                progress.value = progress
            }
            onFinished: {
                console.log("Download finished: " + JSON.stringify(downloadTask.activemod))
                for (var i = 0; i < downloadTask.filePaths.length; ++i) {
                    if(!downloadTask.filePaths[i].endsWith(".zip")) {
                        QmlUrlUtils.moveFile(downloadTask.filePaths[i], zipTask.targetDir)
                    }
                }
                zipTask.sources = downloadTask.filePaths.filter(function (s) { return s.endsWith(".zip") })
                if (zipTask.sources.length === 0) {
                    console.log("No zip files found in download")
                    return
                }
                zipTask.start()
            }

            onError: function(err) {
                console.log("Download failed: " + err)
                modDownloadExtractError.title = qsTr("Download failed");
                modDownloadExtractError.text = err;
                modDownloadExtractError.open();
                progress.value = 0
                installedModsGrid.reload();
                stack.reload();
            }
        }

        ZipExtractionTask {
            id: zipTask
            onProgress: {
                progress.value = progress
            }
            onFinished: {
                console.log("Zip extraction finished")
                installedModsGrid.reload();
                stack.reload();
            }
            onError: function (err) {
                console.log("Zip extraction failed: " + err)
                modDownloadExtractError.title = qsTr("Zip extraction failed");
                modDownloadExtractError.text = err;
                modDownloadExtractError.open();
                progress.value = 0
                QmlUrlUtils.deleteFolder(zipTask.targetDir)
                installedModsGrid.reload();
                stack.reload();
            }
        }

        MProgressBar {
            id: progress
            visible: downloadTask.active || zipTask.active
            Layout.fillWidth: true
            value: 0
            indeterminate: value < 0.01
            label: qsTr("Download Progress")
            width: parent.width
            Layout.preferredHeight: 30
        }
    }
}
