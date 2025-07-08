import QtQuick 2.9
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.2
import io.mrarm.mcpelauncher 1.0

ScrollView {
    id: scrollView
    Layout.fillWidth: true
    Layout.fillHeight: true
    contentHeight: Math.max(gridLayout.implicitHeight + 2 * gridLayout.padding, parent.height)
    property var list: null
    property var model: null

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
            model: scrollView.model

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
            onClicked: scrollView.list.loadMods()
            visible: list && scrollView.list.articlesCount > 0 && scrollView.list.articlesOffset < scrollView.list.articlesCount
            enabled: list && !scrollView.list.articlesLoading
        }
    }

    MBusyIndicator {
        anchors.centerIn: parent
        visible: modsGrid.model === null
    }
}