import QtQuick
import QtQuick.Window
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls
import "ThemedControls"
import io.mrarm.mcpelauncher 1.0

ScrollView {
    Layout.fillHeight: true
    Layout.fillWidth: true
    clip: true
    property GoogleVersionChannel playVerChannel
    id: ldevsettings
    GridLayout {
        columns: 2
        columnSpacing: 20
        rowSpacing: 8
        id: gridLayout12
        property int labelFontSize: 12

        MCheckBox {
            text: qsTr("Show unverified versions")
            font.pointSize: parent.labelFontSize
            Layout.columnSpan: 2
            Component.onCompleted: checked = launcherSettings.showUnverified
            onCheckedChanged: launcherSettings.showUnverified = checked
        }

        MCheckBox {
            text: qsTr("Show incompatible versions")
            font.pointSize: parent.labelFontSize
            Layout.columnSpan: 2
            Component.onCompleted: checked = launcherSettings.showUnsupported
            onCheckedChanged: launcherSettings.showUnsupported = checked
        }

        MCheckBox {
            text: qsTr("Show Beta Versions")
            font.pointSize: parent.labelFontSize
            Layout.columnSpan: 2
            Component.onCompleted: checked = ldevsettings.playVerChannel.latestVersionIsBeta && launcherSettings.showBetaVersions
            onCheckedChanged: launcherSettings.showBetaVersions = checked
            enabled: ldevsettings.playVerChannel.latestVersionIsBeta
        }
    }
}
