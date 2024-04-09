import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "ThemedControls"

ColumnLayout {
    width: parent.width
    spacing: 10
    Keys.forwardTo: versions

    Flow {
        spacing: 10

        MButton {
            Layout.fillWidth: true
            text: qsTr("Delete selected")
            onClicked: {
                if (versions.currentIndex == -1)
                    return
                versionManager.removeVersion(versions.model[versions.currentIndex])
            }
        }

        MButton {
            Layout.fillWidth: true
            text: (googleLoginHelper.account !== null && playVerChannel.hasVerifiedLicense || !LAUNCHER_ENABLE_GOOGLE_PLAY_LICENCE_CHECK) ? qsTr("Import .apk") : qsTr("<s>Import .apk</s> ( Unable to validate ownership )")
            onClicked: apkImportWindow.pickFile()
            enabled: (googleLoginHelper.account !== null && playVerChannel.hasVerifiedLicense || !LAUNCHER_ENABLE_GOOGLE_PLAY_LICENCE_CHECK)
        }

        MButton {
            Layout.fillWidth: true
            text: qsTr("Remove Incompatible Versions")
            onClicked: {
                var abis = googleLoginHelper.getAbis(false)
                for (var i = 0; i < versions.model.length; ++i) {
                    var foundcompatible = false
                    var incompatible = []
                    for (var j = 0; j < versions.model[i].archs.length; ++j) {
                        var found = false
                        for (var k = 0; k < abis.length; ++k) {
                            if (found = versions.model[i].archs[j] === abis[k]) {
                                break
                            }
                        }
                        if (!found) {
                            incompatible.push(versions.model[i].archs[j])
                        } else {
                            foundcompatible = true
                        }
                    }
                    if (!foundcompatible) {
                        versionManager.removeVersion(versions.model[i])
                    } else if (incompatible.length) {
                        versionManager.removeVersion(versions.model[i], incompatible)
                    }
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: Math.max(window.height - 180, 150)
        color: "#1e1e1e"

        ListView {
            id: versions
            anchors.fill: parent
            anchors.margins: 4
            clip: true
            flickableDirection: Flickable.VerticalFlick
            model: versionManagerInstance.versions.getAll().sort(function (a, b) {
                return b.versionCode - a.versionCode
            })
            delegate: ItemDelegate {
                id: control
                width: parent.width
                height: 32
                font.pointSize: 11
                contentItem: Text {
                    text: modelData.versionName + " (" + modelData.archs.join(", ") + ")"
                    color: "#fff"
                    font.pointSize: 10
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: versions.currentIndex = index
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

    ApkImportWindow {
        id: apkImportWindow
        versionManager: versionManagerInstance
        allowIncompatible: launcherSettings.showUnsupported
    }
}
