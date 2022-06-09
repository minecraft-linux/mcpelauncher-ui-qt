import QtQuick
import QtQuick.Layouts
import "ThemedControls"

Item {
    id: newsContainer

    Layout.alignment: Qt.AlignCenter
    Layout.fillWidth: true
    Layout.fillHeight: true

    property int selectedEntry: 0

    Repeater {

        id: repeater

        delegate: MouseArea {
            id: item
            width: parent.width
            height: parent.height
            visible: state == "active" || trOut.running
            cursorShape: Qt.PointingHandCursor

            Image {
                id: newsImage
                width: parent.width
                height: parent.height
                fillMode: Image.PreserveAspectFit
                source: modelData.image
            }

            Rectangle {
                x: newsImage.x + newsImage.width / 2 - width / 2
                y: newsImage.height - height
                width: Math.min(newsContainer.width, Math.max(newsImage.paintedWidth, newsText.implicitWidth))
                height: Math.min(childrenRect.height, parent.height)
                color: "#A0000000"

                Text {
                    width: Math.min(newsContainer.width, Math.max(newsImage.paintedWidth, newsText.implicitWidth))
                    id: newsText
                    font.weight: Font.Bold
                    text: modelData.name
                    color: "white"
                    padding: 8
                    elide: Text.ElideRight
                }
            }

            states: [
                State {
                    name: "inactive_right"
                    when: index > selectedEntry
                    PropertyChanges {
                        target: item
                        x: newsContainer.width
                    }
                },
                State {
                    name: "inactive_left"
                    when: index < selectedEntry
                    PropertyChanges {
                        target: item
                        x: -newsContainer.width
                    }
                },
                State {
                    name: "active"
                    when: index == selectedEntry && !isLoading()
                    PropertyChanges {
                        target: item
                        x: 0
                    }
                }
            ]
            transitions: [
                Transition {
                    id: trIn
                    from: "inactive_right,inactive_left"
                    to: "active"
                    PropertyAnimation { properties: "x"; duration: 500; easing.type: Easing.InOutSine }
                },
                Transition {
                    id: trOut
                    from: "active"
                    to: "inactive_right,inactive_left"
                    PropertyAnimation { properties: "x"; duration: 500; easing.type: Easing.InOutSine }
                }
            ]

            function isLoading() {
                return newsImage.status != Image.Ready
            }

            onClicked: Qt.openUrlExternally(modelData.url)

        }
    }

    function next() {
        if (repeater.count > 0)
            selectedEntry = (selectedEntry + 1) % repeater.count
    }

    Timer {
        id: sliderTimer
        running: false
        interval: 7000
        repeat: true
        onTriggered: function() { next(); }
    }


    MBusyIndicator {
        x: parent.width / 2 - width / 2
        y: parent.height / 2 - height / 2
        visible: repeater.model === null || repeater.itemAt(selectedEntry) === null || repeater.itemAt(selectedEntry).isLoading()
    }

    function loadNews() {
        var req = new XMLHttpRequest();
        req.open("GET", "https://www.minecraft.net/content/minecraft-net/_jcr_content.articles.grid?tileselection=auto&tagsPath=minecraft:article/news,minecraft:article/insider,minecraft:article/culture,minecraft:article/merch,minecraft:stockholm/news,minecraft:stockholm/guides,minecraft:stockholm/events,minecraft:stockholm/minecraft-builds,minecraft:stockholm/marketplace,minecraft:stockholm/deep-dives,minecraft:stockholm/merch,minecraft:stockholm/earth,minecraft:stockholm/dungeons,minecraft:stockholm/realms-plus,minecraft:stockholm/minecraft,minecraft:stockholm/realms-java,minecraft:stockholm/nether&propResPath=/content/minecraft-net/language-masters/en-us/jcr:content/root/generic-container/par/bleeding_page_sectio_1278766118/page-section-par/grid&count=2000&pageSize=20&lang=/content/minecraft-net/language-masters/en-us", true);
        req.onerror = function() {
            console.log("Failed to load news");
        };
        req.onreadystatechange = function() {
            if (req.readyState === XMLHttpRequest.DONE) {
                if (req.status === 200)
                    parseNewsResponse(JSON.parse(req.responseText));
                else
                    req.onerror();
            }
        };
        req.send();
    }
    function parseNewsResponse(resp) {
        var entries = [];
        for (var i = 0; i < resp.article_grid.length; i++) {
            var e = resp.article_grid[i];
            var t = e.preferred_tile || e.default_tile;
            if (!t)
                continue;
            entries.push({"name": t.title || t.text, "image": "https://www.minecraft.net/" + t.image.imageURL, "url": "https://minecraft.net/" + e.article_url.substr(1)});
        }
        repeater.model = entries;
        sliderTimer.start()
    }


    Component.onCompleted: loadNews()
}
