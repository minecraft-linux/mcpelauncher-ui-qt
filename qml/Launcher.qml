import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "ThemedControls"

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
            Item {
                Layout.fillHeight: true
            }
            MSideBarItem {
                text: qsTr("Settings")
                iconSource: "qrc:/Resources/icon-settings.png"
                showText: useWideLayout
                onClicked: updateIndex(2)
                checked: currentIndex == 2
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
        LauncherMain {
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
        MinecraftNews {}
    }

    Component {
        id: launcherSettingsPage
        LauncherSettingsWindow {
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
            mainStackView.push(launcherSettingsPage)
        }

        currentIndex = index
    }
}
