import QtQuick 2.9
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.2
import io.mrarm.mcpelauncher 1.0

import "Components"

AnimatedStackLayout {
    id: stack
    property var elem: null

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

            ScrollView {
                id: scrollView
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: Math.max(gridLayout.implicitHeight + 2 * gridLayout.padding, parent.height)

                GridLayout {
                    id: gridLayout
                    property int cellSize: Math.min(Math.max(500, stackLayout.height / 3), 900)
                    property int padding: 15
                    x: padding
                    y: padding
                    width: parent.width - padding * 2
                    columns: Math.max(Math.round(width / cellSize), 1)
                    columnSpacing: padding
                    rowSpacing: padding

                    Repeater {
                        id: modsGrid
                        model: null

                        Rectangle {
                            id: contentBox
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.columnSpan: 1
                            Layout.rowSpan: 1
                            color: "#222"
                            height: iconImage.height + 20

                            Item {
                                anchors.fill: parent
                                anchors.margins: 10

                                Image {
                                    id: iconImage
                                    width: 100
                                    height: 100
                                    fillMode: Image.PreserveAspectFit
                                    source: modelData.image || "qrc:/Resources/icon-home.png"
                                    smooth: false
                                }

                                Column {
                                    anchors.left: iconImage.right
                                    anchors.leftMargin: 10
                                    height: iconImage.height + 20
                                    width: parent.width - iconImage.width - 30
                                    spacing: 5

                                    Text {
                                        id: titleText
                                        text: modelData.name
                                        width: parent.width
                                        font.bold: true
                                        color: "#fff"
                                        font.pointSize: 13
                                        font.weight: Font.Bold
                                        wrapMode: Text.Wrap
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        id: descriptionText
                                        text: modelData.description
                                        width: parent.width
                                        height: parent.height - titleText.height - 20
                                        color: "#bbb"
                                        font.pointSize: 10
                                        wrapMode: Text.Wrap
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            FocusBorder {
                                visible: mouseArea.activeFocus
                            }

                            states: State {
                                name: "hovered"
                                when: mouseArea.hovered
                            }

                            transitions: [
                                Transition {
                                    to: "hovered"
                                    NumberAnimation {
                                        target: contentBox
                                        property: "scale"
                                        to: 1.0 + (12 / contentBox.width)
                                        duration: 180
                                        easing.type: Easing.OutCubic
                                    }
                                },
                                Transition {
                                    to: "*"
                                    NumberAnimation {
                                        target: contentBox
                                        property: "scale"
                                        to: 1.0
                                        duration: 100
                                        easing.type: Easing.OutSine
                                    }
                                }
                            ]

                            MouseArea {
                                id: mouseArea
                                property bool hovered: false
                                cursorShape: Qt.PointingHandCursor
                                anchors.fill: parent
                                hoverEnabled: true
                                focus: true
                                activeFocusOnTab: true

                                onEntered: hovered = true
                                onExited: hovered = false
                                onClicked: {
                                    hovered = false
                                    openArticle()
                                }
                                Keys.onSpacePressed: openArticle()

                                function openArticle() {
                                    stack.elem = modelData
                                    stack.currentIndex = 1
                                }
                            }
                        }
                    }

                    MButton {
                        Layout.columnSpan: parent.columns
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Load more Mods")
                        onClicked: list.loadMods()
                        visible: list.articlesCount > 0 && list.articlesOffset < list.articlesCount && false
                        enabled: !list.articlesLoading
                    }
                }

                MBusyIndicator {
                    anchors.centerIn: parent
                    visible: modsGrid.model === null
                }
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: Math.max(gridLayout2.implicitHeight + 2 * gridLayout2.padding, parent.height)

                GridLayout {
                    id: gridLayout2
                    property int cellSize: Math.min(Math.max(500, stackLayout.height / 3), 900)
                    property int padding: 15
                    x: padding
                    y: padding
                    width: parent.width - padding * 2
                    columns: Math.max(Math.round(width / cellSize), 1)
                    columnSpacing: padding
                    rowSpacing: padding

                    Repeater {
                        id: modsGrid2
                        model: {
                            reload();
                        }

                        property var reload: function () {
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
                            modsGrid2.model = Object.values(modByName);
                        }

                        Rectangle {
                            id: contentBox
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.columnSpan: 1
                            Layout.rowSpan: 1
                            color: "#222"
                            height: iconImage2.height + 20

                            Item {
                                anchors.fill: parent
                                anchors.margins: 10

                                Image {
                                    id: iconImage2
                                    width: 100
                                    height: 100
                                    fillMode: Image.PreserveAspectFit
                                    source: modelData.image || "qrc:/Resources/icon-home.png"
                                    smooth: false
                                }

                                Column {
                                    anchors.left: iconImage2.right
                                    anchors.leftMargin: 10
                                    height: iconImage2.height + 20
                                    width: parent.width - iconImage2.width - 30
                                    spacing: 5

                                    Text {
                                        id: titleText2
                                        text: modelData.name
                                        width: parent.width
                                        font.bold: true
                                        color: "#fff"
                                        font.pointSize: 13
                                        font.weight: Font.Bold
                                        wrapMode: Text.Wrap
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: modelData.description
                                        width: parent.width
                                        height: parent.height - titleText2.height - 20
                                        color: "#bbb"
                                        font.pointSize: 10
                                        wrapMode: Text.Wrap
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            FocusBorder {
                                visible: mouseArea2.activeFocus
                            }

                            states: State {
                                name: "hovered"
                                when: mouseArea2.hovered
                            }

                            transitions: [
                                Transition {
                                    to: "hovered"
                                    NumberAnimation {
                                        target: contentBox
                                        property: "scale"
                                        to: 1.0 + (12 / contentBox.width)
                                        duration: 180
                                        easing.type: Easing.OutCubic
                                    }
                                },
                                Transition {
                                    to: "*"
                                    NumberAnimation {
                                        target: contentBox
                                        property: "scale"
                                        to: 1.0
                                        duration: 100
                                        easing.type: Easing.OutSine
                                    }
                                }
                            ]

                            MouseArea {
                                id: mouseArea2
                                property bool hovered: false
                                cursorShape: Qt.PointingHandCursor
                                anchors.fill: parent
                                hoverEnabled: true
                                focus: true
                                activeFocusOnTab: true

                                onEntered: hovered = true
                                onExited: hovered = false
                                onClicked: {
                                    hovered = false
                                    openArticle()
                                }
                                Keys.onSpacePressed: openArticle()

                                function openArticle() {
                                    stack.elem = modelData
                                    stack.currentIndex = 1
                                }
                            }
                        }
                    }
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
                                enabled: (modelData.assets[arch] && modelData.assets[arch].length > 0 || false) && !progress.active
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
                                    modsGrid2.reload();
                                    var s = stack;
                                    var bck = s.elem;
                                    s.elem = {};
                                    s.elem = bck;
                                    s.currentIndex = 1
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
                                    modsGrid2.reload();
                                    var s = stack;
                                    var bck = s.elem;
                                    s.elem = {};
                                    s.elem = bck;
                                    s.currentIndex = 1
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

            MButton {
                visible: false
                text: qsTr("Download")
                onClicked: {
                    progress.indeterminate = true
                }
            }
        }

        DownloadDataWrapper {
            id: download1
        }

        DownloadTask {
            id: downloadTask
            property var activemod: null
            keepDownload: true
            onProgress: {
                progress.value = progress
            }
            onFinished: {
                console.log("Download finished: " + JSON.stringify(downloadTask.activemod))
                zipTask.sources = downloadTask.filePaths
                zipTask.start()
            }
        }

        ZipExtractionTask {
            id: zipTask
            onProgress: {
                progress.value = progress
            }
            onFinished: {
                console.log("Zip extraction finished")
                // if (downloadTask.activemod) {
                //     modManager.reloadMod(downloadTask.activemod.name, downloadTask.activemod.version, downloadTask.activemod.arch)
                //     modsGrid2.reload();
                //     var s = stack;
                //     var bck = s.elem;
                //     s.elem = {};
                //     s.elem = bck;
                //     s.currentIndex = 1
                // }
            }
            onError: function (err) {
                console.log("Zip extraction error: " + err)
                progress.indeterminate = false
                progress.value = 0
            }
        }

        MProgressBar {
            id: progress
            visible: downloadTask.active || zipTask.active
            Layout.fillWidth: true
            value: 0.8
            indeterminate: value < 0.01
            label: qsTr("Download Progress")
            width: parent.width
            Layout.preferredHeight: 30
        }
    }
}
