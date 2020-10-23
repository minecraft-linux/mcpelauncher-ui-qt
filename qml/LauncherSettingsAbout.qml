import QtQuick 2.0

import QtQuick.Layouts 1.2
import QtQuick.Controls 2.2
import "ThemedControls"

ColumnLayout {
    id: columnlayout
    property var maximumWidth: 100
    MButton {
        text: qsTr("Show Changelog")
        onClicked: stackView.push(panelChangelog)
    }
    TextEdit {
        textFormat: TextEdit.RichText
        text: qsTr("This project allows you to launch Minecraft: Bedrock Edition (as in the edition w/o the Edition suffix, previously known as Minecraft: Pocket Edition). The launcher supports Linux and OS X.<br/><br/>Version %1 (build %2)<br/> © Copyright 2018-2020, MrARM & contributors").arg(LAUNCHER_VERSION_NAME).arg(LAUNCHER_VERSION_CODE)
        readOnly: true
        wrapMode: Text.WordWrap
        selectByMouse: true
        Layout.maximumWidth: columnlayout.maximumWidth
    }

}
