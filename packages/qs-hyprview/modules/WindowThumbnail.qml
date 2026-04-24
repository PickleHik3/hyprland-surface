import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects

Item {
    id: thumbContainer

    property var hWin: null
    property var wHandle:null
    property var effectiveHandle: null

    property string winKey: ''

    property real thumbW: -1
    property real thumbH: -1

    property var clientInfo: {}
    property bool hovered: false
    property var exposeRoot: null
    property int workspaceId: -1
    readonly property string windowAddress: hWin ? ("0x" + String(hWin.address)) : ""
    property bool dropHandled: false
    property bool tilePressed: false
    property bool dragMode: false
    property bool swipePreview: false

    property real targetX: -1000
    property real targetY: -1000
    property real targetZ: 0
    property real targetRotation: 0

    property bool moveCursorToActiveWindow: false

    width: thumbW
    height: thumbH

    x: 0
    y: 0
    z: targetZ
    rotation: 0

    visible: !!effectiveHandle

    NumberAnimation {
        id: animX
        target: thumbContainer
        property: "x"
        duration: root.animateWindows ? 100 : 0
        easing.type: Easing.OutQuad
    }
    NumberAnimation {
        id: animY
        target: thumbContainer
        property: "y"
        duration: root.animateWindows ? 100 : 0
        easing.type: Easing.OutQuad
    }
    NumberAnimation {
        id: animRotation
        target: thumbContainer
        property: "rotation"
        duration: 400
        easing.type: Easing.OutBack // Effetto rimbalzo/inerzia
        easing.overshoot: 1.2
    }

    function updateLastPos() {
        var lp = root.lastPositions || ({})
        var prev = lp[winKey] || ({})
        prev.x = x
        prev.y = y
        lp[winKey] = prev
        root.lastPositions = lp
    }

    onTargetXChanged: {
        if (!root.animateWindows) {
            x = targetX
            updateLastPos()
            return
        }

        var lp = root.lastPositions || ({})
        var prev = lp[winKey]
        var startX = (prev && prev.x !== undefined) ? prev.x : targetX

        if (startX === targetX) {
            x = targetX
            updateLastPos()
            return
        }

        animX.stop()
        animX.from = startX
        animX.to = targetX
        animX.start()
    }

    onTargetYChanged: {
        if (!root.animateWindows) {
            y = targetY
            updateLastPos()
            return
        }

        var lp = root.lastPositions || ({})
        var prev = lp[winKey]
        var startY = (prev && prev.y !== undefined) ? prev.y : targetY

        if (startY === targetY) {
            y = targetY
            updateLastPos()
            return
        }

        animY.stop()
        animY.from = startY
        animY.to = targetY
        animY.start()
    }

    onTargetRotationChanged: {
        rotation = targetRotation
        animRotation.stop()
        animRotation.from = 0
        animRotation.to = targetRotation
        animRotation.start()
    }

    onXChanged: updateLastPos()
    onYChanged: updateLastPos()

    Component.onCompleted: {
        if (wHandle) effectiveHandle = wHandle
        rotation = targetRotation
        if (!root.animateWindows) {
            x = targetX
            y = targetY
            updateLastPos()
        }
    }

    onWHandleChanged: {
        // Keep last known valid handle to avoid capture source flapping.
        if (wHandle) effectiveHandle = wHandle
    }

    function activateWindow() {
        if (!hWin) return

        var targetIsSpecial = (hWin?.workspace ?? 0) < 0 || (hWin?.workspace?.name ?? "").startsWith("special")

        if (root.specialActive && !targetIsSpecial) {
            Hyprland.dispatch("togglespecialworkspace")
        }

        if (hWin.workspace) {
            hWin.workspace.activate()
        }

        root.toggleExpose()
        Hyprland.dispatch("focuswindow address:0x" + hWin.address)
        Hyprland.dispatch("alterzorder top")
        if (thumbContainer.moveCursorToActiveWindow) {
          var cx = clientInfo.at[0] + (clientInfo.size[0]/2)
          var cy = clientInfo.at[1] + (clientInfo.size[1]/2)
        Hyprland.dispatch("movecursor " + cx + " " + cy)

        }
    }

    function closeWindow() {
        if (!hWin) return
        Hyprland.dispatch("closewindow address:0x" + hWin.address)
    }

    function currentWorkspaceId() {
        if (workspaceId > 0)
            return Number(workspaceId)
        if (hWin && hWin.workspace && hWin.workspace.id !== undefined)
            return Number(hWin.workspace.id)
        if (clientInfo && clientInfo.workspace && clientInfo.workspace.id !== undefined)
            return Number(clientInfo.workspace.id)
        return -1
    }

    function sendToWorkspace(workspaceId) {
        if (!exposeRoot || !thumbContainer.windowAddress || workspaceId < 1)
            return
        exposeRoot.moveWindowToWorkspace(thumbContainer.windowAddress, workspaceId)
    }

    function refreshThumb() {
        if (thumbLoader.item) {
            thumbLoader.item.captureFrame()
        }
    }

    Item {
        id: card
        anchors.fill: parent

        scale: 1.0
        transformOrigin: Item.Center

        MouseArea {
            id: dragArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton

            property real startX: 0
            property real startY: 0
            property real startSceneX: 0
            property real startSceneY: 0
            property real startItemX: 0
            property real startItemY: 0
            property bool swipeTriggered: false
            property bool dragMoved: false

            function eventPoint(event) {
                return dragArea.mapToItem(null, event.x, event.y)
            }

            function resetGestureState() {
                longPressTimer.stop()
                thumbContainer.tilePressed = false
                thumbContainer.dragMode = false
                thumbContainer.swipePreview = false
                thumbContainer.Drag.active = false
                if (exposeRoot) {
                    exposeRoot.draggingFromWorkspace = -1
                    exposeRoot.draggingTargetWorkspace = -1
                }
            }

            onEntered: {
                exposeArea.currentIndex = index
            }
            onPressed: event => {
                var point = eventPoint(event)
                startX = event.x
                startY = event.y
                startSceneX = point.x
                startSceneY = point.y
                startItemX = thumbContainer.x
                startItemY = thumbContainer.y
                swipeTriggered = false
                dragMoved = false
                thumbContainer.tilePressed = true
                thumbContainer.dragMode = false
                thumbContainer.swipePreview = false
                thumbContainer.dropHandled = false
                thumbContainer.Drag.source = thumbContainer
                thumbContainer.Drag.hotSpot.x = event.x
                thumbContainer.Drag.hotSpot.y = event.y
                longPressTimer.restart()
            }
            onPositionChanged: event => {
                if (!thumbContainer.tilePressed)
                    return

                var dx = event.x - startX
                var dy = event.y - startY
                var distance = Math.abs(dx) + Math.abs(dy)

                if (!thumbContainer.dragMode && distance > 18)
                    longPressTimer.stop()

                if (thumbContainer.dragMode) {
                    var point = eventPoint(event)
                    dx = point.x - startSceneX
                    dy = point.y - startSceneY
                    thumbContainer.x = startItemX + dx
                    thumbContainer.y = startItemY + dy
                    dragMoved = true
                    return
                }

                var upwardIntent = dy < -12 && Math.abs(dy) > Math.abs(dx) * 0.8
                if (upwardIntent) {
                    thumbContainer.swipePreview = true
                    thumbContainer.x = startItemX
                    thumbContainer.y = startItemY + Math.min(0, dy)
                    if (Math.abs(dy) > 24)
                        dragMoved = true
                } else {
                    thumbContainer.swipePreview = false
                    thumbContainer.x = startItemX
                    thumbContainer.y = startItemY
                }

                if (!swipeTriggered && dy < -90 && Math.abs(dx) < 170 && Math.abs(dy) > (Math.abs(dx) * 0.9)) {
                    swipeTriggered = true
                    thumbContainer.closeWindow()
                }
            }
            onClicked: event => {
                if (swipeTriggered || dragMoved) {
                    event.accepted = true
                    return
                }
                exposeArea.currentIndex = index

                if (event.button === Qt.LeftButton) {
                    thumbContainer.activateWindow()
                }
                if (event.button === Qt.MiddleButton) {
                    thumbContainer.closeWindow()
                }
            }
            onExited: {
                if (exposeArea.currentIndex === index) {
                    exposeArea.currentIndex = -1
                }
            }
            onReleased: {
                var targetWorkspace = (exposeRoot ? exposeRoot.draggingTargetWorkspace : -1)
                var currentWorkspace = (hWin && hWin.workspace) ? hWin.workspace.id : -1
                if (!swipeTriggered && thumbContainer.dragMode && exposeRoot && targetWorkspace > 0 && targetWorkspace !== currentWorkspace && thumbContainer.windowAddress) {
                    exposeRoot.moveWindowToWorkspace(thumbContainer.windowAddress, targetWorkspace)
                }
                Qt.callLater(function() {
                    dragArea.resetGestureState()
                    thumbContainer.x = thumbContainer.targetX
                    thumbContainer.y = thumbContainer.targetY
                })
            }
            onCanceled: {
                dragArea.resetGestureState()
                thumbContainer.x = thumbContainer.targetX
                thumbContainer.y = thumbContainer.targetY
            }

            Timer {
                id: longPressTimer
                interval: 420
                repeat: false
                onTriggered: {
                    if (!thumbContainer.tilePressed)
                        return
                    thumbContainer.dragMode = true
                    thumbContainer.swipePreview = false
                    if (exposeRoot)
                        exposeRoot.draggingFromWorkspace = thumbContainer.currentWorkspaceId()
                    thumbContainer.Drag.active = true
                }
            }
        }

        RectangularShadow {
            anchors.fill: parent
            radius: 16
            blur: (exposeRoot && exposeRoot.efficientMode && exposeRoot.thumbCount > 8) ? 14 : 24
            spread: (exposeRoot && exposeRoot.efficientMode && exposeRoot.thumbCount > 8) ? 5 : 10
            color: "#55000000"
            cached: true
            visible: false
        }

        Loader {
            id: thumbLoader
            anchors.fill: parent
            active: root.isActive && !!thumbContainer.effectiveHandle
            sourceComponent: ScreencopyView {
                id: thumb
                anchors.fill: parent
                captureSource: thumbContainer.effectiveHandle
                live: (root.liveCapture
                    || ((exposeRoot && exposeRoot.dynamicLiveCapture)
                        && (thumbContainer.hovered || exposeArea.currentIndex === index)))
                    && root.isActive
                paintCursor: false
                visible: root.isActive && !!thumbContainer.effectiveHandle

                layer.enabled: false

                Rectangle {
                    anchors.fill: parent
                    color: thumbContainer.hovered ? "transparent": "#33000000"
                    border.width : (thumbContainer.hovered || thumbContainer.dragMode || thumbContainer.swipePreview) ? 2 : 1
                    border.color : exposeRoot
                        ? ((thumbContainer.hovered || thumbContainer.dragMode || thumbContainer.swipePreview) ? exposeRoot.dmsPrimary : exposeRoot.dmsOutline)
                        : ((thumbContainer.hovered || thumbContainer.dragMode || thumbContainer.swipePreview) ? "#ff0088cc" : "#cc444444")
                    radius: 16
                }
            }
        }

        Rectangle {
            id: titleBar
            z: 120
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: Math.max(34, Math.min(42, thumbContainer.height * 0.14))
            anchors.leftMargin: 2
            anchors.rightMargin: 2
            anchors.topMargin: 2
            radius: 12
            clip: true
            color: exposeRoot ? exposeRoot.withAlpha(exposeRoot.dmsSurfaceContainer, 0.94) : "#dd111111"
            border.width: 1
            border.color: exposeRoot ? exposeRoot.dmsOutline : "#55333333"

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: exposeRoot ? exposeRoot.withAlpha(exposeRoot.dmsOutline, 0.65) : "#55ffffff"
            }

            Rectangle {
                id: workspaceChip
                width: Math.max(44, workspaceLabel.implicitWidth + 16)
                height: Math.max(24, titleBar.height - 10)
                radius: height / 2
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                color: exposeRoot ? exposeRoot.withAlpha(exposeRoot.dmsSurface, 0.76) : "#66000000"
                border.width: 1
                border.color: exposeRoot ? exposeRoot.dmsOutline : "#66ffffff"

                Text {
                    id: workspaceLabel
                    anchors.centerIn: parent
                    text: "WS " + Math.max(1, thumbContainer.currentWorkspaceId())
                    color: exposeRoot ? exposeRoot.dmsOnSurface : "white"
                    font.pixelSize: 12
                    font.bold: true
                }
            }

            Rectangle {
                id: closeButton
                width: Math.min(30, titleBar.height - 8)
                height: width
                radius: width / 2
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 8
                color: closeMouse.pressed
                    ? (exposeRoot ? exposeRoot.dmsPrimary : "#ffffffff")
                    : (exposeRoot ? exposeRoot.withAlpha(exposeRoot.dmsSurface, 0.72) : "#66000000")
                border.width: 1
                border.color: exposeRoot ? exposeRoot.dmsPrimary : "#88ffffff"

                Text {
                    anchors.centerIn: parent
                    text: "x"
                    color: closeMouse.pressed
                        ? (exposeRoot ? exposeRoot.dmsSurface : "black")
                        : (exposeRoot ? exposeRoot.dmsOnSurface : "white")
                    font.pixelSize: 16
                    font.bold: true
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    onClicked: {
                        thumbContainer.closeWindow()
                    }
                }
            }

            MouseArea {
                id: titleBarGesture
                anchors.left: parent.left
                anchors.right: closeButton.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.rightMargin: 8
                anchors.leftMargin: workspaceChip.width + 14
                acceptedButtons: Qt.LeftButton

                property real startSceneX: 0
                property real startSceneY: 0
                property bool handled: false

                function eventPoint(event) {
                    return titleBarGesture.mapToItem(null, event.x, event.y)
                }

                onPressed: event => {
                    var point = eventPoint(event)
                    startSceneX = point.x
                    startSceneY = point.y
                    handled = false
                }

                onReleased: event => {
                    if (handled)
                        return
                    var point = eventPoint(event)
                    var dx = point.x - startSceneX
                    var dy = point.y - startSceneY
                    if (Math.abs(dx) < 64 || Math.abs(dx) < Math.abs(dy) * 1.25)
                        return

                    var currentWorkspace = thumbContainer.currentWorkspaceId()
                    if (dx < 0) {
                        if (currentWorkspace > 1)
                            thumbContainer.sendToWorkspace(currentWorkspace - 1)
                    } else if (currentWorkspace > 0) {
                        thumbContainer.sendToWorkspace(currentWorkspace + 1)
                    }
                    handled = true
                }
            }
        }

        Rectangle {
            id: badge
            z: 100
            width: Math.min(titleText.implicitWidth + 24, thumbContainer.thumbW * 0.75)
            height: titleText.implicitHeight + 12

            x: (card.width - width) / 2
            y: card.height - height - (card.height * 0.08)

            radius: 12
            color: thumbContainer.hovered ? "#FF000000" : "#CC000000"
            border.width : 1
            border.color : "#ff464646"

            Text {
                id: titleText
                anchors.centerIn: parent
                width: parent.width - 16
                text: hWin.title
                color: "white"
                font.pixelSize: thumbContainer.hovered ? 13 : 12
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
