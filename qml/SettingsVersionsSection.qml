import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "Components"
import io.mrarm.mcpelauncher 1.0

ColumnLayout {
    width: parent.width
    spacing: 10
    Keys.forwardTo: versions
    id: layout

    Component {
        id: downloadApkComponent
        Popup {
            id: downloadApk
            background: Rectangle {
                color: "#333"
            }
            height: scope.implicitHeight + 20
            width: layout.width
            modal: true
            clip: true

            property int currentCode: versionBox.codes[versionBox.currentIndex]

            property bool showVersionListTrial: packageField.text == "com.mojang.minecrafttrialpe"
            property bool showVersionList: packageField.text == "com.mojang.minecraftpe" || showVersionListTrial
            property var currentVersionCode: function () {
                return (manualgoogleLoginHelperInstance.chromeOS && showVersionList && (currentCode > 982000000 && currentCode < 990000000 || currentCode > 972000000 && currentCode < 980000000) ? 1000000000 : 0) + currentCode
            }

            Overlay.modal: Rectangle {
                id: popupOverlay
                color: "#8f181818"
            }
            ColumnLayout {
                anchors.fill: parent
                id: scope
                property var playVersion: null

                MTextField {
                    id: packageField
                    Layout.fillWidth: true
                    Component.onCompleted: {
                        packageField.text = launcherSettings.trialMode ? "com.mojang.minecrafttrialpe" : "com.mojang.minecraftpe"
                    }
                    onEditingFinished: {
                        manualplayApi.requestAppInfo(packageField.text)
                    }
                }

                MComboBox {
                    Layout.fillWidth: true
                    id: versionBox
                    property var codes: []
                    model: {
                        var ret = []
                        var ncodes = []
                        if (scope.playVersion !== null) {
                            ret.push(scope.playVersion.versionName)
                            ncodes.push(scope.playVersion.versionCode)
                        }
                        if (downloadApk.showVersionList) {
                            for (var i = 0; i < versionManager.archivalVersions.versions.length; i++) {
                                var ver = versionManager.archivalVersions.versions[i]
                                if ((scope.playVersion && scope.playVersion.isBeta || !ver.isBeta) && (!downloadApk.showVersionListTrial || ver.abi.indexOf("x86") !== -1)) {
                                    ret.push(ver.versionName + " (" + ver.abi + ")")
                                    ncodes.push(ver.versionCode)
                                }
                            }
                        }
                        codes = ncodes
                        return ret
                    }

                    onActivated: {
                        versionsCodeField.text = downloadApk.currentVersionCode().toString()
                    }
                    Component.onCompleted: versionsCodeField.text = downloadApk.currentVersionCode().toString()
                }

                MCheckBox {
                    id: isChromeOS
                    text: qsTr("IsChromeOS")
                    Layout.bottomMargin: 10
                    Component.onCompleted: {
                        packageField.text = launcherSettings.chromeOSMode
                    }
                }

                GoogleLoginHelper {
                    id: manualgoogleLoginHelperInstance
                    includeIncompatible: true
                    singleArch: ""
                    unlockkey: googleLoginHelperInstance.unlockkey
                    chromeOS: isChromeOS.checked
                    onAccountInfoChanged: {
                        versionsCodeField.text = downloadApk.currentVersionCode().toString()
                    }
                }

                GooglePlayApi {
                    id: manualplayApi
                    login: manualgoogleLoginHelperInstance

                    onInitError: function (err) {
                        console.log("Failed " + err)
                    }
                    onAppInfoReceived: function (packageName, version, versionCode, isBeta) {
                        scope.playVersion = {
                            "versionName": version,
                            "versionCode": versionCode,
                            "isBeta": isBeta
                        }
                        versionsCodeField.text = downloadApk.currentVersionCode().toString()
                    }
                    onAppInfoFailed: function (packageName, err) {
                        scope.playVersion = null
                        versionsCodeField.text = downloadApk.currentVersionCode().toString()
                    }

                    onReady: {
                        manualplayApi.requestAppInfo(packageField.text)
                    }
                }

                property var apkUrls: ""

                GoogleApkDownloadTask {
                    id: manualPlayDownloadTask
                    playApi: manualplayApi
                    packageName: packageField.text
                    keepApks: false
                    dryrun: true
                    versionCode: Number.parseInt(versionsCodeField.text)
                    onActiveChanged: {
                        if (manualPlayDownloadTask.active) {
                            scope.apkUrls = ""
                        }
                    }
                    onDownloadInfo: function (url) {
                        scope.apkUrls = url
                    }
                    onError: function (err) {
                        scope.apkUrls = err
                    }
                    onFinished: {
                        console.log("done")
                    }
                }

                MTextField {
                    id: versionsCodeField
                    Layout.fillWidth: true
                }

                MButton {
                    text: qsTr("Get Download Info")
                    onClicked: manualPlayDownloadTask.start()
                }

                Flickable {
                    id: flick

                    Layout.fillWidth: true
                    height: 100
                    contentWidth: edit.contentWidth
                    contentHeight: edit.contentHeight
                    clip: true

                    function ensureVisible(r) {
                        if (contentX >= r.x)
                            contentX = r.x
                        else if (contentX + width <= r.x + r.width)
                            contentX = r.x + r.width - width
                        if (contentY >= r.y)
                            contentY = r.y
                        else if (contentY + height <= r.y + r.height)
                            contentY = r.y + r.height - height
                    }

                    TextEdit {
                        id: edit
                        focus: true
                        wrapMode: TextEdit.Wrap
                        onCursorRectangleChanged: flick.ensureVisible(cursorRectangle)
                        text: "<style type=\"text/css\">a { color: lightblue; }</style>" + scope.apkUrls
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

                MButton {
                    text: qsTr("Close")
                    onClicked: downloadApk.close()
                }
            }
        }
    }

    Flow {
        Layout.fillWidth: true
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

        Loader {
            id: downloadApkLoader
            onLoaded: {
                downloadApkLoader.item.open()
            }
        }

        MButton {
            Layout.fillWidth: true
            text: qsTr("Download .apk")
            onClicked: {
                if (downloadApkLoader.item) {
                    downloadApkLoader.item.open()
                } else {
                    downloadApkLoader.sourceComponent = downloadApkComponent
                }
            }
            enabled: (googleLoginHelper.account !== null)
        }

        MButton {
            Layout.fillWidth: true
            text: launcherSettings.trialMode ? qsTr("Import trial .apk") : qsTr("Import .apk")
            onClicked: apkImportWindow.pickFile()
            enabled: (googleLoginHelper.account !== null && playVerChannel.hasVerifiedLicense || launcherSettings.trialMode || !LAUNCHER_ENABLE_GOOGLE_PLAY_LICENCE_CHECK)
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
