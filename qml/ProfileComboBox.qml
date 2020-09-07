import QtQuick 2.0
import QtQuick.Controls 2.2
import "ThemedControls"

MComboBox {
    property var profiles: profileManager.profiles
    property int addProfileIndex: profiles.length
    property var currentProfile: profiles[0]

    signal addProfileSelected()

    function getProfile() {
        return currentProfile
    }
    function setProfile(profile) {
        for (var i = 0; i < profiles.length; i++) {
            if (profiles[i] === profile) {
                if (currentIndex !== i)
                    currentIndex = i
                if (currentProfile !== profiles[i])
                    currentProfile = profiles[i]
                return true
            }
        }
        return false
    }
    function onAddProfileResult(newProfile) {
        if (newProfile !== null && setProfile(newProfile))
            return;
        if (!setProfile(currentProfile)) {
            currentIndex = 0
            currentProfile = profiles[0]
        }
    }

    id: control

    model: {
        var ret = []
        for (var i = 0; i < profiles.length; i++)
            ret.push(profiles[i].name)
        ret.push("Add new profile...")
        return ret
    }

    delegate: ItemDelegate {
        property bool hasSeparator: index == addProfileIndex

        width: parent.width
        height: 32 + (separator.visible ? separator.height : 0)
        text: modelData
        highlighted: control.highlightedIndex === index

        Rectangle {
            id: separator
            width: parent.width
            height: 1
            color: 'black'
            visible: hasSeparator
        }

        contentItem: Text {
            anchors.fill: parent
            anchors.leftMargin: parent.padding
            anchors.rightMargin: parent.padding
            anchors.topMargin: (separator.visible ? separator.height : 0)
            text: modelData
            font.pointSize: 11
            verticalAlignment: Text.AlignVCenter
        }
    }

    onActivated: function(index) {
        if (index === addProfileIndex)
            addProfileSelected()
        else
            currentProfile = profiles[index]
    }

    onModelChanged: {
        if (!setProfile(currentProfile))
            currentIndex = 0
    }
}
