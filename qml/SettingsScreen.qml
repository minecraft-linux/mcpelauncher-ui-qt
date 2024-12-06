import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Components"
import io.mrarm.mcpelauncher 1.0

ColumnLayout {
    property GoogleLoginHelper googleLoginHelper
    property VersionManager versionManager
    property string currentGameDataDir
    property GoogleVersionChannel playVerChannel
    spacing: 0

    BaseHeader {
        title: qsTr("Settings")
        content: TabBar {
            id: tabs
            background: null

            MTabButton {
                text: qsTr("General")
            }
            MTabButton {
                text: qsTr("Storage")
            }
            MTabButton {
                text: qsTr("Versions")
            }
            MTabButton {
                text: qsTr("Dev")
                visible: !(DISABLE_DEV_MODE)
                width: !(DISABLE_DEV_MODE) ? implicitWidth : 0
            }
            MTabButton {
                text: qsTr("About")
            }

            Keys.forwardTo: settingsStackLayout.children[currentIndex]
        }
    }

    AnimatedStackLayout {
        id: settingsStackLayout
        currentIndex: tabs.currentIndex
        Layout.fillHeight: true
        Layout.fillWidth: true

        CenteredScrollView {
            content: SettingsGeneralSection {}
        }
        CenteredScrollView {
            content: SettingsStorageSection {}
        }
        CenteredScrollView {
            content: SettingsVersionsSection {}
        }
        CenteredScrollView {
            content: SettingsDevSection {}
        }
        CenteredScrollView {
            content: SettingsAboutSection {}
        }
    }
}
