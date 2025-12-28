import QtQuick 2.9
import QtQuick.Layouts 1.2
import "ThemedControls"

ColumnLayout {
    property color labelColor: "#fff"
    property int labelFontSize: 10
    width: parent.width
    spacing: 10

    Rectangle {
        color: "#30ff8000"
        Layout.fillWidth: true
        Layout.bottomMargin: 15
        Layout.minimumHeight: warningText.height
        radius: 4
        Text {
            id: warningText
            padding: 10
            text: qsTr("Warning: This Section is for Launcher Developers and are not documented. Do not use Developer Settings without deep understanding how they impact the Launcher.")
            color: labelColor
            font.pointSize: labelFontSize
            wrapMode: Text.WordWrap
            width: parent.width
        }
    }

    MCheckBox {
        text: qsTr("Show unverified versions")
        font.pointSize: labelFontSize
        Component.onCompleted: checked = launcherSettings.showUnverified
        onCheckedChanged: launcherSettings.showUnverified = checked
        Layout.bottomMargin: 10
    }

    GridLayout {
        columns: 2
        columnSpacing: 10
        rowSpacing: 10
        Layout.fillWidth: true

        Text {
            text: qsTr("Single arch mode")
            font.pointSize: labelFontSize
            color: labelColor
            Layout.columnSpan: 1
        }
        MComboBox {
            Layout.columnSpan: 1

            id: profileTexturePatch
            Layout.fillWidth: true

            textRole: "name"
            model: ListModel {
                ListElement {
                    name: ""
                }
                ListElement {
                    name: "armeabi-v7a"
                }
                ListElement {
                    name: "arm64-v8a"
                }
                ListElement {
                    name: "x86"
                }
                ListElement {
                    name: "x86_64"
                }
            }

            Component.onCompleted: {
                console.log("launcherSettings.singleArch " + launcherSettings.singleArch)
                for (var i = 0; i < model.count; i++) {
                    if (launcherSettings.singleArch == model.get(i).name) {
                        currentIndex = i
                        break
                    }
                }
            }

            onActivated: function (index) {
                console.log("onActivated")
                var val = model.get(index).name
                console.log(val)
                launcherSettings.singleArch = val
            }
        }

        Text {
            text: qsTr("Versions feed base url")
            font.pointSize: labelFontSize
            color: labelColor
            Layout.columnSpan: 1
        }
        MTextField {
            id: versionsFeedBaseUrl
            Layout.columnSpan: 1
            Layout.fillWidth: true
            Component.onCompleted: versionsFeedBaseUrl.text = launcherSettings.versionsFeedBaseUrl
            onEditingFinished: {
                launcherSettings.versionsFeedBaseUrl = versionsFeedBaseUrl.text
                versionManager.downloadLists(googleLoginHelper.getAbis(true), launcherSettings.versionsFeedBaseUrl)
            }
        }
    }
}
