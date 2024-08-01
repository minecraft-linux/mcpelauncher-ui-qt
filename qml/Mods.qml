import QtQuick 2.9
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.2
import "ThemedControls"

StackLayout {
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
                    enabled: false
                    text: qsTr("Installed Mods")
                }
                MTabButton {
                    text: qsTr("FAQ")
                }
            }
        }

        StackLayout {
            currentIndex: tabs.currentIndex
            Layout.fillWidth: true
            Layout.fillHeight: true

            ScrollView {
                id: scrollView
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: Math.max(gridLayout.height + 2 * gridLayout.padding, availableHeight)

                GridLayout {
                    id: gridLayout
                    property int cellSize: Math.min(Math.max(250, window.height / 3), 400)
                    property int padding: 15
                    anchors.centerIn: parent
                    width: parent.width - padding * 2
                    columns: 1
                    columnSpacing: padding
                    rowSpacing: padding

                    Repeater {
                        id: newsGrid
                        model: null

                        Rectangle {
                            id: contentBox
                            Layout.minimumHeight: 300
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.columnSpan: 1
                            Layout.rowSpan: 1
                            color: "#222"

                            Image {
                                id: newsImage
                                property real ratio: 1
                                anchors.top: parent.top
                                anchors.bottom: descriptionBox.top
                                width: parent.width
                                fillMode: Image.PreserveAspectCrop
                                source: modelData.image || "qrc:/Resources/icon-home.png"
                                smooth: false
                            }

                            Rectangle {
                                id: descriptionBox
                                width: parent.width
                                height: descriptionContent.height
                                anchors.bottom: parent.bottom
                                color: "#111"
                                Column {
                                    id: descriptionContent
                                    width: parent.width
                                    padding: 15
                                    spacing: 5

                                    Text {
                                        text: modelData.name
                                        width: parent.width - 2 * parent.padding
                                        color: "#fff"
                                        font.pointSize: 13
                                        font.weight: Font.Bold
                                        wrapMode: Text.WordWrap
                                    }
                                    Text {
                                        text: modelData.description
                                        width: parent.width - 2 * parent.padding
                                        color: "#bbb"
                                        font.pointSize: 10
                                        wrapMode: Text.WordWrap
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
                    visible: newsGrid.model === null
                }
            }

            MText {

            }

            TextEdit {
                focus: true
                Layout.fillWidth: true
                wrapMode: "WordWrap"
                text: "<style type=\"text/css\">a { color: lightblue; }</style>" + qsTr("Welcome to our experimental mods section, managing mods is not supported yet.<br/>To contribute your mod open a PR to <a href=\"https://github.com/minecraft-linux/mcpelauncher-moddb\">minecraft-linux/mcpelauncher-moddb</a><br/>Mods are placed inside the mods folder under the data root found in Settings>Storage \"data root\" button, you have to create this folder and it doesn't exist by default.<br/><font color=\"#f66\">Do not report crashs to the issue tracker of the launcher with enabled mods.</font>")

                color: "white"
                textFormat: Text.RichText
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
            var url = "https://github.com/minecraft-linux/mcpelauncher-moddb/raw/f1ee3ce411339deda6827876a0ae958c9b9d5344/moddb.json"

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
            if (newsGrid.model === null) {
                newsGrid.model = resp
            } else {
                var model = newsGrid.model;
                model.push.apply(model, resp)
                newsGrid.model = model
            }
        }

        Component.onCompleted: loadMods()
    }
    ColumnLayout{
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            RowLayout {
                MButton {
                    text: qsTr("Back")
                    onClicked: {
                        stack.currentIndex = 0
                    }
                }

                MText {
                    font.bold: true
                    font.pointSize: 20
                    text: stack.elem && stack.elem.name || qsTr("Untitled Mod")
                }
            }

            Image {
                width: parent.width
                fillMode: Image.PreserveAspectCrop
                source: stack.elem && stack.elem.image || "qrc:/Resources/icon-home.png"
                smooth: false
            }

            MText {
                text: stack.elem && stack.elem.description || ""
            }

            MText {
                text: stack.elem && stack.elem.url || ""

            }

            TextEdit {
                id: edit
                focus: true
                wrapMode: TextEdit.Wrap
                text: "<style type=\"text/css\">a { color: lightblue; }</style><a href=\"" + (stack.elem && stack.elem.url && stack.elem.url.indexOf("\"") === -1 && stack.elem.url || "") + "\">Homepage</a>"
                color: "white"
                textFormat: Text.RichText
                readOnly: true
                selectByMouse: true
                onLinkActivated: Qt.openUrlExternally(link)

                MouseArea {
                    anchors.fill: parent
                    cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                    acceptedButtons: Qt.NoButton
                }
            }

            ListView {
                activeFocusOnTab: true
                id: downloads
                Layout.fillWidth: true
                Layout.fillHeight: true
                anchors.margins: 4
                clip: true
                flickableDirection: Flickable.VerticalFlick
                model: {
                    if(!stack.elem) {
                        return [];
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
                            enabled: modelData.assets[arch] && modelData.assets[arch].length > 0 || false
                            onClicked: {
                                console.log(JSON.stringify(modelData.assets))
                                console.log(arch)
                                Qt.openUrlExternally(modelData.assets[arch])
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

            MButton {
                visible: false
                text: qsTr("Download")
                onClicked: {
                    progress.indeterminate = true
                }
            }

            MProgressBar {
                visible: false
                id: progress
                Layout.fillWidth: true
                value: 0.8
                indeterminate: false
                label: qsTr("Download Progress")
                width: parent.width
                Layout.preferredHeight: 20
            }
        }}
