import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.2
import QtQuick.Controls 2.2
import "ThemedControls"

ScrollView {
    Layout.fillHeight: true
    Layout.fillWidth: true
    clip: true
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
            Component.onCompleted: checked = launcherSettings.showBetaVersions
            onCheckedChanged: launcherSettings.showBetaVersions = checked
            enabled: playVerChannel.latestVersionIsBeta
        }
    }
}