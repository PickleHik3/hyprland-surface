import QtQuick
import qs.Common
import qs.Widgets

Rectangle {
    id: root

    property string iconName: ""
    property color iconColor: Theme.surfaceText
    property color backgroundColor: "transparent"
    property bool indicatorVisible: false
    property color indicatorColor: Theme.primary
    property int buttonSize: 36
    signal clicked

    width: buttonSize
    height: buttonSize
    radius: Math.round(buttonSize / 2)
    color: mouseArea.containsMouse ? Theme.surfaceContainerHighest : backgroundColor

    Behavior on color {
        ColorAnimation {
            duration: Theme.shorterDuration
            easing.type: Theme.standardEasing
        }
    }

    DankIcon {
        anchors.centerIn: parent
        name: root.iconName
        size: Math.max(16, root.buttonSize - Theme.spacingL)
        color: root.iconColor
    }

    Rectangle {
        visible: root.indicatorVisible
        width: 8
        height: 8
        radius: 4
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 2
        anchors.bottomMargin: 2
        color: root.indicatorColor
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
