import QtQuick
import QtQuick.Controls
import QtQuick.Templates as T
import QtQuick.Window

T.ComboBox {
    id: control

    implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
    implicitHeight: 36
    baselineOffset: contentItem.y + contentItem.baselineOffset
    leftPadding: 8
    rightPadding: 36

    background: BorderImage {
        id: buttonBackground
        anchors.fill: parent
        source: (control.hovered || control.activeFocus) || control.down ? "qrc:/Resources/dropdown-active.png" : "qrc:/Resources/dropdown.png"
        smooth: false
        border { left: 4; top: 4; right: 32; bottom: 4 }
        horizontalTileMode: BorderImage.Stretch
        verticalTileMode: BorderImage.Stretch
    }

    indicator: Item {
        width: 36
        height: 36
    }

    contentItem: Text {
        id: textItem
        text: control.displayText
        font.pointSize: 11
        opacity: enabled ? 1.0 : 0.3
        color: "#000"
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    delegate: ItemDelegate {
        width: parent ? parent.width : 0
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
            source: "qrc:/Resources/dropdown-bg.png"
            smooth: false
            border { left: 4; top: 4; right: 4; bottom: 4 }
            horizontalTileMode: BorderImage.Stretch
            verticalTileMode: BorderImage.Stretch
        }
    }
}
