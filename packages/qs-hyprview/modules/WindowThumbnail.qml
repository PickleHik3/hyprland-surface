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
    property bool swipeDismissing: false
    property real swipeTravel: 0

    property real targetX: -1000
    property real targetY: -1000
    property real targetZ: 0
    property real targetRotation: 0
    readonly property real dismissThreshold: {
        var base = Math.max(150, Math.min(220, thumbContainer.height * 0.28))
        var topRowBias = Math.max(0, 260 - thumbContainer.targetY) * 0.16
        return Math.max(132, base - topRowBias)
    }
    readonly property real previewOffset: Math.max(0, thumbContainer.targetY - thumbContainer.y)
    readonly property real previewProgress: Math.min(1, thumbContainer.previewOffset / thumbContainer.dismissThreshold)

    property bool moveCursorToActiveWindow: false
    property string displayTitle: {
        var title = String(hWin && hWin.title ? hWin.title : clientInfo && clientInfo.title ? clientInfo.title : "")
        if (title.trim().length > 0)
            return title
        var clazz = String(clientInfo && clientInfo.initialClass ? clientInfo.initialClass : clientInfo && clientInfo["class"] ? clientInfo["class"] : hWin && hWin.appId ? hWin.appId : "Window")
        return clazz
    }
    property string secondaryTitle: {
        var clazz = String(clientInfo && clientInfo.initialClass ? clientInfo.initialClass : clientInfo && clientInfo["class"] ? clientInfo["class"] : hWin && hWin.appId ? hWin.appId : "")
        var normalized = clazz.replace(/[_-]+/g, " ").trim()
        return normalized.length > 0 ? normalized : ""
    }

    width: thumbW
    height: thumbH

    x: 0
    y: 0
    z: targetZ
    rotation: 0
    opacity: 1.0 - (((thumbContainer.swipePreview || thumbContainer.swipeDismissing) ? thumbContainer.previewProgress : 0) * 0.16)

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
    NumberAnimation {
        id: swipeReturnAnimation
        target: thumbContainer
        property: "y"
        duration: 180
        easing.type: Easing.OutCubic
        onFinished: {
            thumbContainer.swipePreview = false
            thumbContainer.swipeDismissing = false
            thumbContainer.swipeTravel = 0
            thumbContainer.x = thumbContainer.targetX
            thumbContainer.y = thumbContainer.targetY
        }
    }
    NumberAnimation {
        id: swipeDismissAnimation
        target: thumbContainer
        property: "y"
        duration: 165
        easing.type: Easing.InCubic
        onFinished: {
            thumbContainer.swipePreview = false
            thumbContainer.swipeDismissing = false
            thumbContainer.swipeTravel = 0
            thumbContainer.closeWindow()
        }
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

    function restoreSwipePosition() {
        swipeDismissAnimation.stop()
        swipeReturnAnimation.stop()
        swipeReturnAnimation.from = thumbContainer.y
        swipeReturnAnimation.to = thumbContainer.targetY
        swipeReturnAnimation.start()
    }

    function dismissWithSwipe() {
        swipeReturnAnimation.stop()
        swipeDismissAnimation.stop()
        thumbContainer.swipeDismissing = true
        swipeDismissAnimation.from = thumbContainer.y
        swipeDismissAnimation.to = thumbContainer.targetY - Math.max(thumbContainer.height * 1.1, thumbContainer.dismissThreshold + 96)
        swipeDismissAnimation.start()
    }

    Item {
        id: card
        anchors.fill: parent

        scale: 1.0 - (((thumbContainer.swipePreview || thumbContainer.swipeDismissing) ? thumbContainer.previewProgress : 0) * 0.04)
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
                thumbContainer.swipeDismissing = false
                thumbContainer.swipeTravel = 0
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

                var travel = Math.max(0, -dy)
                var upwardIntent = travel >= 26 && travel > Math.abs(dx) * 0.72

                if (thumbContainer.swipePreview) {
                    if (travel <= 10) {
                        thumbContainer.swipePreview = false
                        thumbContainer.swipeTravel = 0
                        thumbContainer.x = startItemX
                        thumbContainer.y = startItemY
                        return
                    }

                    thumbContainer.swipeTravel = travel
                    thumbContainer.x = startItemX
                    thumbContainer.y = startItemY - Math.min(travel * 0.94, thumbContainer.height * 1.15)
                    if (travel > 40)
                        dragMoved = true
                    return
                }

                if (upwardIntent) {
                    thumbContainer.swipePreview = true
                    thumbContainer.swipeTravel = travel
                    thumbContainer.x = startItemX
                    thumbContainer.y = startItemY - Math.min(travel * 0.94, thumbContainer.height * 1.15)
                    if (travel > 40)
                        dragMoved = true
                } else {
                    thumbContainer.swipePreview = false
                    thumbContainer.swipeTravel = 0
                    thumbContainer.x = startItemX
                    thumbContainer.y = startItemY
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
            onReleased: event => {
                var targetWorkspace = (exposeRoot ? exposeRoot.draggingTargetWorkspace : -1)
                var currentWorkspace = (hWin && hWin.workspace) ? hWin.workspace.id : -1
                var swipeDistance = Math.max(thumbContainer.previewOffset, thumbContainer.swipeTravel)
                var horizontalDistance = Math.abs(event.x - startX)

                if (thumbContainer.swipePreview && !thumbContainer.dragMode) {
                    dragArea.resetGestureState()
                    if (swipeDistance >= thumbContainer.dismissThreshold &&
                        horizontalDistance < Math.min(thumbContainer.width * 0.30, 140)) {
                        swipeTriggered = true
                        thumbContainer.dismissWithSwipe()
                    } else {
                        thumbContainer.restoreSwipePosition()
                    }
                    return
                }

                if (!swipeTriggered && thumbContainer.dragMode && exposeRoot && targetWorkspace > 0 && targetWorkspace !== currentWorkspace && thumbContainer.windowAddress) {
                    exposeRoot.moveWindowToWorkspace(thumbContainer.windowAddress, targetWorkspace)
                }
                Qt.callLater(function() {
                    dragArea.resetGestureState()
                    thumbContainer.swipePreview = false
                    thumbContainer.swipeDismissing = false
                    thumbContainer.swipeTravel = 0
                    thumbContainer.x = thumbContainer.targetX
                    thumbContainer.y = thumbContainer.targetY
                })
            }
            onCanceled: {
                dragArea.resetGestureState()
                if (thumbContainer.swipePreview) {
                    thumbContainer.restoreSwipePosition()
                    return
                }
                thumbContainer.swipePreview = false
                thumbContainer.swipeDismissing = false
                thumbContainer.swipeTravel = 0
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
            radius: 20
            blur: (exposeRoot && exposeRoot.efficientMode && exposeRoot.thumbCount > 8) ? 12 : 20
            spread: (exposeRoot && exposeRoot.efficientMode && exposeRoot.thumbCount > 8) ? 4 : 7
            color: exposeRoot ? exposeRoot.withAlpha(exposeRoot.dmsSurface, 0.28) : "#55000000"
            cached: true
            visible: true
        }

        Rectangle {
            id: cardFrame
            anchors.fill: parent
            radius: 20
            color: exposeRoot ? exposeRoot.withAlpha(exposeRoot.dmsSurfaceContainer, 0.90) : "#22000000"
            border.width: (thumbContainer.hovered || thumbContainer.dragMode || thumbContainer.swipePreview) ? 2 : 1
            border.color: exposeRoot
                ? ((thumbContainer.hovered || thumbContainer.dragMode || thumbContainer.swipePreview)
                    ? exposeRoot.dmsPrimary
                    : exposeRoot.withAlpha(exposeRoot.dmsOutline, 0.48))
                : "#66666666"
        }

        Loader {
            id: thumbLoader
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: footerBar.top
            anchors.margins: 10
            anchors.bottomMargin: 8
            active: root.isActive && !!thumbContainer.effectiveHandle
            sourceComponent: ScreencopyView {
                id: thumb
                anchors.fill: parent
                captureSource: thumbContainer.effectiveHandle
                live: (root.liveCapture
                    || ((exposeRoot && exposeRoot.dynamicLiveCapture)
                        && !thumbContainer.swipePreview
                        && !thumbContainer.swipeDismissing
                        && (thumbContainer.hovered || exposeArea.currentIndex === index)))
                    && root.isActive
                paintCursor: false
                visible: root.isActive && !!thumbContainer.effectiveHandle

                layer.enabled: false

                Rectangle {
                    anchors.fill: parent
                    color: thumbContainer.hovered ? "transparent" : (exposeRoot ? exposeRoot.withAlpha(exposeRoot.dmsSurface, 0.06) : "#22000000")
                    radius: 14
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: Math.max(32, parent.height * 0.12)
                    radius: 14
                    color: exposeRoot ? exposeRoot.withAlpha(exposeRoot.dmsSurface, 0.16) : "#66000000"
                    border.width: 0

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        height: 1
                        color: exposeRoot ? exposeRoot.withAlpha(exposeRoot.dmsOutline, 0.22) : "#33ffffff"
                    }
                }
            }
        }

        Rectangle {
            id: workspaceChip
            z: 120
            width: Math.max(24, workspaceLabel.implicitWidth + 12)
            height: 24
            radius: 12
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: 14
            anchors.topMargin: 14
            color: exposeRoot ? exposeRoot.withAlpha(exposeRoot.dmsSurfaceRaised, 0.98) : "#66000000"
            border.width: 1
            border.color: exposeRoot ? exposeRoot.withAlpha(exposeRoot.dmsOutlineVariant, 0.82) : "#66ffffff"

            Text {
                id: workspaceLabel
                anchors.centerIn: parent
                text: String(Math.max(1, thumbContainer.currentWorkspaceId()))
                color: exposeRoot ? exposeRoot.dmsOnSurface : "white"
                font.pixelSize: 12
                font.bold: true
            }
        }

        Rectangle {
            id: closeButton
            z: 120
            width: 24
            height: 24
            radius: 12
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 14
            anchors.topMargin: 14
            color: closeMouse.pressed
                ? (exposeRoot ? exposeRoot.dmsPrimary : "#ffffffff")
                : (exposeRoot ? exposeRoot.withAlpha(exposeRoot.dmsSurfaceRaised, 0.98) : "#66000000")
            border.width: 1
            border.color: exposeRoot ? exposeRoot.withAlpha(exposeRoot.dmsOutlineVariant, 0.82) : "#88ffffff"

            Text {
                anchors.centerIn: parent
                text: "x"
                color: closeMouse.pressed
                    ? (exposeRoot ? exposeRoot.dmsSurface : "black")
                    : (exposeRoot ? exposeRoot.dmsOnSurface : "white")
                font.pixelSize: 14
                font.bold: true
            }

            MouseArea {
                id: closeMouse
                anchors.fill: parent
                onClicked: thumbContainer.closeWindow()
            }
        }

        Rectangle {
            id: footerBar
            z: 100
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 10
            height: 54
            radius: 14
            color: exposeRoot
                ? exposeRoot.withAlpha(exposeRoot.dmsSurfaceRaised, thumbContainer.hovered ? 0.98 : 0.95)
                : "#cc111111"
            border.width: 1
            border.color: exposeRoot ? exposeRoot.withAlpha(exposeRoot.dmsOutlineVariant, 0.72) : "#55555555"

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 2

                Text {
                    width: parent.width
                    text: thumbContainer.displayTitle
                    color: exposeRoot ? exposeRoot.dmsOnSurface : "white"
                    font.pixelSize: 13
                    font.bold: true
                    elide: Text.ElideRight
                }

                Text {
                    visible: thumbContainer.secondaryTitle.length > 0 && thumbContainer.secondaryTitle !== thumbContainer.displayTitle
                    width: parent.width
                    text: thumbContainer.secondaryTitle
                    color: exposeRoot ? exposeRoot.withAlpha(exposeRoot.dmsMutedText, 0.92) : "#bbbbbb"
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }
        }
    }
}
