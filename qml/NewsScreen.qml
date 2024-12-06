import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "Components"

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
                        anchors.top: parent.top
                        anchors.bottom: descriptionBox.top
                        width: parent.width
                        fillMode: Image.PreserveAspectCrop
                        source: modelData.image
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
                            Qt.openUrlExternally(modelData.url)
                        }
                    }
                }
            }

            MButton {
                Layout.columnSpan: parent.columns
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Load more articles")
                onClicked: loadNews()
                visible: articlesCount > 0 && articlesOffset < articlesCount
                enabled: !articlesLoading
            }
        }

        MBusyIndicator {
            anchors.centerIn: parent
            visible: newsGrid.model === null
        }
    }

    property int articlesCount: 0
    property int articlesOffset: 0
    property int articlesPerPage: 20
    property bool articlesLoading: false

    function loadNews() {
        articlesLoading = true
        var offset = articlesOffset
        if (articlesCount > 0) {
            offset += articlesPerPage
        }
        var req = new XMLHttpRequest()
        var url = "https://www.minecraft.net/content/minecraft-net/_jcr_content.articles.grid?tileselection=auto&tagsPath=minecraft:stockholm/news,minecraft:stockholm/guides,minecraft:stockholm/events,minecraft:stockholm/minecraft-builds,minecraft:stockholm/marketplace,minecraft:stockholm/deep-dives,minecraft:stockholm/merch,minecraft:article/culture,minecraft:article/insider,minecraft:article/merch,minecraft:article/news&propResPath=/content/minecraft-net/language-masters/en-us/jcr:content/root/generic-container/par/bleeding_page_sectio_1278766118/page-section-par/grid"
        url += `&offset=${offset}&count=2000&pageSize=${articlesPerPage}&lang=/content/minecraft-net/language-masters/en-us`

        req.open("GET", url, true)
        req.onerror = function () {
            console.log("Failed to load news")
            articlesLoading = false
        }
        req.onreadystatechange = function () {
            if (req.readyState === XMLHttpRequest.DONE) {
                if (req.status === 200) {
                    parseNewsResponse(JSON.parse(req.responseText))
                    articlesOffset = offset
                } else {
                    req.onerror()
                }
            }
            articlesLoading = false
        }
        req.send()
    }

    function parseNewsResponse(resp) {
        articlesCount = resp.article_count
        var entries = []
        for (var i = 0; i < resp.article_grid.length; i++) {
            var e = resp.article_grid[i]
            var t = e.preferred_tile || e.default_tile
            if (!t)
                continue
            entries.push({
                             "name": t.title || t.text,
                             "description": t.sub_header,
                             "image": "https://www.minecraft.net/" + t.image.imageURL,
                             "url": "https://minecraft.net/" + e.article_url.substr(1)
                         })
            console.log(t.title)
        }
        if (newsGrid.model === null) {
            newsGrid.model = entries
        } else {
            newsGrid.model.push(...entries)
        }
    }

    Component.onCompleted: loadNews()
}
