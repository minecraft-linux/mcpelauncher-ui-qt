import QtQuick 2.9
import QtQuick.Layouts 1.2
import "ThemedControls"

Item {
    id: newsContainer

    Layout.alignment: Qt.AlignCenter
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.margins: 16

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

                onStatusChanged: function() {
                    if (status == Image.Ready)
                        show();
                }
            }

            Rectangle {
                x: newsImage.x + newsImage.width / 2 - width / 2
                y: newsImage.height - height
                width: newsImage.paintedWidth
                height: childrenRect.height
                color: "#A0000000"

                Text {
                    font.weight: Font.Bold
                    text: modelData.name
                    color: "white"
                    padding: 8
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
        console.log("Load news");
        var req = new XMLHttpRequest();
        req.open("GET", "https://minecraft.net/en-us/api/tiles/channel/not_set/region/None/category/News", true);
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
        for (var i = 0; i < resp.result.length; i++) {
            var e = resp.result[i];
            var t = e.preferred_tile || e.default_tile;
            if (!t)
                continue;
            entries.push({"name": t.title || t.text, "image": t.image.original.url, "url": "https://minecraft.net/" + e.url.substr(1)});
        }
        repeater.model = entries
        console.log("Loaded " + entries.length + " items");
        sliderTimer.start()
    }


    Component.onCompleted: loadNews()
}
