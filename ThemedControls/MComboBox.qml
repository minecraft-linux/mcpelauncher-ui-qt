import QtQuick 2.0
import QtQuick.Controls 2.2
import QtQuick.Templates 2.1 as T
import QtQuick.Window 2.3

T.ComboBox {
    id: control

    padding: 8
    implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
    implicitHeight: 36
    baselineOffset: contentItem.y + contentItem.baselineOffset

    background: BorderImage {
        id: buttonBackground
        anchors.fill: parent
        source: control.hovered || popup.visible ? "../Resources/dropdown-active.png" : "../Resources/dropdown.png"
        smooth: false
        border { left: 4; top: 4; right: 32; bottom: 4 }
        horizontalTileMode: BorderImage.Stretch
        verticalTileMode: BorderImage.Stretch
    }

    contentItem: Text {
        id: textItem
        text: control.displayText
        font.pointSize: 11
        opacity: enabled ? 1.0 : 0.3
        color: "#000"
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
    }

    delegate: ItemDelegate {
        width: parent.width
        height: 32
        font.pointSize: 11
        text: control.textRole ? (Array.isArray(control.model) ? modelData[control.textRole] : model[control.textRole]) : modelData
        highlighted: control.highlightedIndex === index
    }

    popup: T.Popup {
        y: control.height
        width: control.width
        height: Math.min(contentItem.implicitHeight + topPadding + bottomPadding, control.Window.height - topMargin - bottomMargin)
        topMargin: 6
        bottomMargin: 6
        padding: 4

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.delegateModel
            currentIndex: control.highlightedIndex
            highlightMoveDuration: 0
        }

        background: BorderImage {
            source: "../Resources/dropdown-bg.png"
            smooth: false
            border { left: 4; top: 4; right: 4; bottom: 4 }
            horizontalTileMode: BorderImage.Stretch
            verticalTileMode: BorderImage.Stretch
        }
    }
}
