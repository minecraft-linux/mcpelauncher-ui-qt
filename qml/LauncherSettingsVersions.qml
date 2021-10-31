import QtQuick 2.0

import QtQuick.Layouts 1.2
import QtQuick.Controls 2.2
import "ThemedControls"

ColumnLayout {
    Keys.forwardTo: children[1].children[0]
    Layout.fillWidth: true
    ColumnLayout {

        MButton {
            Layout.fillWidth: true
            text: qsTr("Delete selected")
            onClicked: {
                if (versions.currentIndex == -1)
                    return;
                versionManager.removeVersion(versions.model[versions.currentIndex])
            }
        }

        MButton {
            Layout.fillWidth: true
            text: (googleLoginHelper.account !== null && playVerChannel.hasVerifiedLicense || !LAUNCHER_ENABLE_GOOGLE_PLAY_LICENCE_CHECK) ? qsTr("Import .apk") : qsTr("<s>Import .apk</s> (You have to own the game)")
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
                                break;
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
                    } else if (incompatible.length){
                        versionManager.removeVersion(versions.model[i], incompatible)
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }

    }

    BorderImage {
        Layout.fillWidth: true
        Layout.fillHeight: true
        source: "qrc:/Resources/dropdown-bg.png"
        smooth: false
        border { left: 4; top: 4; right: 4; bottom: 4 }
        horizontalTileMode: BorderImage.Stretch
        verticalTileMode: BorderImage.Stretch

        ListView {
            id: versions
            anchors.fill: parent
            anchors.margins: 4
            clip: true
            flickableDirection: Flickable.VerticalFlick
            model: versionManager.versions.getAll().sort(function(a, b) { return b.versionCode - a.versionCode; })
            delegate: ItemDelegate {
                id: control
                width: parent.width - 8
                height: 32
                font.pointSize: 11
                text: modelData.versionName + " (" + modelData.archs.join(", ") + ")"
                onClicked: versions.currentIndex = index
                highlighted: ListView.isCurrentItem
                background: Rectangle {
                    color: control.highlighted ? "#C5CAE9" : (control.down ? "#dddedf" : "transparent")
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
