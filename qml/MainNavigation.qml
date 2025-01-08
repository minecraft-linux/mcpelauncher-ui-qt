import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "Components"

RowLayout {
    spacing: 0
    anchors.fill: parent
    property int currentIndex: 0
    property bool useWideLayout: window.width > 720

    Rectangle {
        Layout.fillHeight: true
        Layout.preferredWidth: sidebarLayout.width
        color: "#1e1e1e"
        z: 3
        ColumnLayout {
            id: sidebarLayout
            height: parent.height - 14
            anchors.centerIn: parent
            MSideBarItem {
                text: qsTr("Home")
                iconSource: "qrc:/Resources/icon-home.png"
                showText: useWideLayout
                onClicked: updateIndex(0)
                checked: currentIndex == 0
            }
            MSideBarItem {
                text: qsTr("News")
                iconSource: "qrc:/Resources/icon-news.png"
                showText: useWideLayout
                onClicked: updateIndex(1)
                checked: currentIndex == 1
            }
            MSideBarItem {
                text: qsTr("Mods")
                iconSource: "qrc:/Resources/icon-mods.png"
                showText: useWideLayout
                onClicked: updateIndex(2)
                checked: currentIndex === 2
            }
            Item {
                Layout.fillHeight: true
            }
            MSideBarItem {
                text: qsTr("Game Log")
                iconSource: "qrc:/Resources/icon-log.png"
                showText: useWideLayout
                onClicked: updateIndex(3)
                checked: currentIndex === 3
            }
            MSideBarItem {
                text: qsTr("Settings")
                iconSource: "qrc:/Resources/icon-settings.png"
                showText: useWideLayout
                onClicked: updateIndex(4)
                checked: currentIndex == 4
            }
            MSideBarItem {
                visible: launcherSettings.showExitButton
                text: qsTr("Exit")
                iconSource: "qrc:/Resources/icon-exit.png"
                showText: useWideLayout
                onClicked: Qt.quit()
                checked: false
            }
        }
    }

    StackView {
        id: mainStackView
        initialItem: launcherHomePage
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.minimumHeight: 200
        Layout.minimumWidth: 400
    }

    Component {
        id: launcherHomePage
        HomeScreen {
            googleLoginHelper: googleLoginHelperInstance
            versionManager: versionManagerInstance
            profileManager: profileManagerInstance
            playApiInstance: playApi
            playVerChannel: playVerChannelInstance
            hasUpdate: window.hasUpdate
            updateDownloadUrl: window.updateDownloadUrl
            isVersionsInitialized: window.isVersionsInitialized
        }
    }

    Component {
        id: launcherNewsPage
        NewsScreen {}
    }

    Component {
        id: launcherModsPage
        ModsScreen {}
    }

    ListModel {
        id: gameLog
    }

    Connections {
        target: gameLauncher
        onLogCleared: gameLog.clear()
        onLogAppended: gameLog.append({
                                          "display": text.substring(0, text.length - 1)
                                      })
    }

    Component {
        id: gameLogPage
        GameLogScreen {
            launcher: gameLauncher
        }
    }

    Component {
        id: launcherSettingsPage
        SettingsScreen {
            googleLoginHelper: googleLoginHelperInstance
            versionManager: versionManagerInstance
            playVerChannel: playVerChannelInstance
        }
    }

    function updateIndex(index) {
        if (index === currentIndex)
            return

        mainStackView.pop(null)

        if (index === 1) {
            mainStackView.push(launcherNewsPage)
        } else if (index === 2) {
            mainStackView.push(launcherModsPage)
        } else if (index === 3) {
            mainStackView.push(gameLogPage)
        } else if (index === 4) {
            mainStackView.push(launcherSettingsPage)
        }

        currentIndex = index
    }
}
