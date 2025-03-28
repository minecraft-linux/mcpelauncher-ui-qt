import QtQuick
import QtQuick.Window
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.platform
import "Components"
import io.mrarm.mcpelauncher 1.0

ColumnLayout {
    id: rowLayout
    spacing: 0

    property alias headerContent: baseHeader.content

    BaseHeader {
        id: baseHeader
        Layout.fillWidth: true
        title: qsTr("Unofficial *nix launcher for Minecraft")
        subtitle: LAUNCHER_VERSION_NAME ? qsTr("%1 (build %2)").arg(LAUNCHER_VERSION_NAME).arg((LAUNCHER_VERSION_CODE || "Unknown").toString()) : ""
    }
}
