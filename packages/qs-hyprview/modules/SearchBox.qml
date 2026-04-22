import QtQuick
import Quickshell

Rectangle {
    id: searchBar
    width: Math.min(parent.width * 0.6, 480)
    height: 40
    radius: 20
    color: withAlpha(backgroundColor, 0.86)
    border.width: 1
    border.color: borderColor
    anchors.horizontalCenter: parent.horizontalCenter

    property var onTextChanged: null
    property color backgroundColor: "#66000000"
    property color borderColor: "#33ffffff"
    property color textColor: "white"
    property color placeholderColor: "#88ffffff"

    function withAlpha(value, alpha) {
        return Qt.rgba(value.r, value.g, value.b, alpha)
    }

    function reset() {
      searchInput.text = ""
    }

    TextInput {
        id: searchInput
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        verticalAlignment: TextInput.AlignVCenter
        color: searchBar.textColor
        font.pixelSize: 16
        activeFocusOnTab: false
        selectByMouse: true
        focus: true

        onTextChanged: {
            searchBar.onTextChanged(text)
        }

        Text {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            color: searchBar.placeholderColor
            font.pixelSize: 14
            text: "Type to filter windows..."
            visible: !searchInput.text || searchInput.text.length === 0
        }
    }
}
