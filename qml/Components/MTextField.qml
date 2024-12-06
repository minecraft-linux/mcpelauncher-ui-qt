import QtQuick
import QtQuick.Controls

TextField {
    id: control
    padding: 8
    implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
    implicitHeight: 35
    verticalAlignment: TextInput.AlignVCenter
    font.pointSize: 10
    selectByMouse: true
    selectionColor: "#51a063"
    color: "#fff"
    placeholderTextColor: "#666"
    opacity: control.enabled ? 1.0 : 0.3

    background: Rectangle {
        border.color: control.hovered ? "#666" : "#555"
        color: "#1e1e1e"
        radius: 2

        FocusBorder {
            visible: control.focus ? control.focusReason == Qt.TabFocusReason || control.focusReason == Qt.BacktabFocusReason : false
        }
    }
}
