import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "ThemedControls"

ColumnLayout {
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: 0

    BaseHeader {
        Layout.fillWidth: true
        title: qsTr("News")
        content: TabBar {
            id: tabs
            background: null
            MTabButton {
                text: qsTr("Minecraft")
            }
        }
    }

    ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentHeight: Math.max(gridLayout.height + 2 * gridLayout.padding, availableHeight)

        GridLayout {
            id: gridLayout
            property int cellSize: Math.min(Math.max(250, window.height / 3), 400)
            property int padding: 15
            anchors.centerIn: parent
            width: parent.width - padding * 2
            columns: Math.max(Math.round(width / cellSize), 2)
            columnSpacing: padding
            rowSpacing: padding

            Repeater {
                id: newsGrid
                model: null

                Rectangle {
                    id: contentBox
                    Layout.minimumHeight: gridLayout.cellSize
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.columnSpan: newsImage.ratio > 1.5 ? 2 : 1
                    Layout.rowSpan: newsImage.ratio < 0.5 ? 2 : 1
                    color: "#222"

                    Image {
                        id: newsImage
                        property real ratio: sourceSize.width / sourceSize.height
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        source: modelData.image
                        smooth: false
                        anchors.bottom: parent.bottom
                    }

                    Rectangle {
                        id: descriptionBox
                        width: parent.width
                        height: 40
                        anchors.bottom: parent.bottom
                        color: "#B0000000"
                        Text {
                            anchors.fill: parent
                            text: modelData.name
                            color: "#fff"
                            font.pointSize: 10
                            font.weight: Font.Bold
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            padding: 8
                        }
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
                        onEntered: hovered = true
                        onExited: hovered = false
                        onClicked: {
                            hovered = false
                            Qt.openUrlExternally(modelData.url)
                        }
                    }
                }
            }
        }

        MBusyIndicator {
            anchors.centerIn: parent
            visible: newsGrid.model === null
        }
    }

    function loadNews() {
        var req = new XMLHttpRequest()
        req.open("GET", "https://www.minecraft.net/content/minecraft-net/_jcr_content.articles.grid?tileselection=auto&tagsPath=minecraft:article/news,minecraft:article/insider,minecraft:article/culture,minecraft:article/merch,minecraft:stockholm/news,minecraft:stockholm/guides,minecraft:stockholm/events,minecraft:stockholm/minecraft-builds,minecraft:stockholm/marketplace,minecraft:stockholm/deep-dives,minecraft:stockholm/merch,minecraft:stockholm/earth,minecraft:stockholm/dungeons,minecraft:stockholm/realms-plus,minecraft:stockholm/minecraft,minecraft:stockholm/realms-java,minecraft:stockholm/nether&propResPath=/content/minecraft-net/language-masters/en-us/jcr:content/root/generic-container/par/bleeding_page_sectio_1278766118/page-section-par/grid&count=2000&pageSize=20&lang=/content/minecraft-net/language-masters/en-us", true)
        req.onerror = function () {
            console.log("Failed to load news")
        }
        req.onreadystatechange = function () {
            if (req.readyState === XMLHttpRequest.DONE) {
                if (req.status === 200)
                    parseNewsResponse(JSON.parse(req.responseText))
                else
                    req.onerror()
            }
        }
        req.send()
    }

    function parseNewsResponse(resp) {
        var entries = []
        for (var i = 0; i < resp.article_grid.length; i++) {
            var e = resp.article_grid[i]
            var t = e.preferred_tile || e.default_tile
            if (!t)
                continue
            entries.push({
                             "name": t.title || t.text,
                             "image": "https://www.minecraft.net/" + t.image.imageURL,
                             "url": "https://minecraft.net/" + e.article_url.substr(1)
                         })
            console.log(t.title)
        }
        newsGrid.model = entries
    }

    Component.onCompleted: loadNews()
}
