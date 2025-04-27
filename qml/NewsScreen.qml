import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "Components"

ColumnLayout {
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: 0

    property int articlesPage: 1
    property bool articlesLoading: false
    property var newsModel: ListModel {}

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
                model: newsModel
                delegate: Rectangle {
                    id: contentBox
                    Layout.minimumHeight: gridLayout.cellSize
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.columnSpan: articleImage.ratio > 1.5 ? 2 : 1
                    Layout.rowSpan: articleImage.ratio < 0.5 ? 2 : 1
                    color: "#222"

                    Image {
                        id: articleImage
                        property real ratio: sourceSize.width / sourceSize.height
                        anchors.top: parent.top
                        anchors.bottom: descriptionBox.top
                        width: parent.width
                        fillMode: Image.PreserveAspectCrop
                        smooth: false
                        source: image
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
                                text: name
                                width: parent.width - 2 * parent.padding
                                color: "#fff"
                                font.pointSize: 13
                                font.weight: Font.Bold
                                wrapMode: Text.WordWrap
                            }
                            Text {
                                text: description
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
                        when: mouseArea.containsMouse && !mouseArea.pressed
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
                        cursorShape: Qt.PointingHandCursor
                        anchors.fill: parent
                        hoverEnabled: true
                        focus: true
                        activeFocusOnTab: true
                        onClicked: openArticle()
                        Keys.onSpacePressed: openArticle()
                        function openArticle() {
                            Qt.openUrlExternally(url)
                        }
                    }
                }
            }

            MButton {
                Layout.columnSpan: parent.columns
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Load more articles")
                onClicked: loadNews()
                visible: newsModel.count > 0
                enabled: !articlesLoading
            }
        }

        MBusyIndicator {
            anchors.centerIn: parent
            visible: newsModel.count < 1
        }
    }

    function loadNews() {
        articlesLoading = true
        var req = new XMLHttpRequest()
        req.open("GET", `https://www.minecraft.net/content/minecraftnet/language-masters/en-us/jcr:content/root/container/image_grid_a_copy_64.articles.page-${articlesPage}.json`, true)
        req.onerror = function (error) {
            console.error("Failed to load news:", error)
            articlesLoading = false
        }
        req.onreadystatechange = function () {
            if (req.readyState === XMLHttpRequest.DONE) {
                if (req.status === 200) {
                    parseNewsResponse(JSON.parse(req.responseText))
                    articlesPage++
                } else {
                    req.onerror(req.statusText)
                }
                articlesLoading = false
            }
        }
        req.send()
    }

    function parseNewsResponse(resp) {
        for (var i = 0; i < resp.article_grid.length; i++) {
            const e = resp.article_grid[i]
            const t = e.preferred_tile || e.default_tile
            if (t) {
                newsModel.append({
                                     "name": t.title || t.text,
                                     "description": t.sub_header,
                                     "image": `https://www.minecraft.net${t.image.imageURL}`,
                                     "url": `https://minecraft.net${e.article_url}`
                                 })
            }
        }
    }

    Component.onCompleted: loadNews()
}
