import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects
import "../layouts"
import "."

PanelWindow {
    id: root

    // --- SETTINGS ---
    property string layoutAlgorithm: "smartgrid"
    property string lastLayoutAlgorithm: "smartgrid"
    property bool liveCapture: false
    property bool moveCursorToActiveWindow: false

    // --- INTERNAL STATE ---
    property bool isActive: false
    property bool specialActive: false
    property bool animateWindows: false
    property var lastPositions: {}
    property int activeWorkspaceId: 1
    property int draggingTargetWorkspace: -1
    property int draggingFromWorkspace: -1
    property bool efficientMode: true
    property int refreshCursor: 0
    readonly property int thumbCount: winRepeater.count
    property int edgePadding: 48
    property int persistentWorkspaceCount: 4
    property int stageMaxWidth: 1640
    readonly property bool dynamicLiveCapture: efficientMode && isActive && thumbCount <= 8
    property color dmsSurface: Palette.surfaceContainerLow ? Palette.surfaceContainerLow : "#1b1b1f"
    property color dmsSurfaceContainer: Palette.surfaceContainerHigh ? Palette.surfaceContainerHigh : "#25262b"
    property color dmsSurfaceRaised: Palette.surfaceContainerHighest ? Palette.surfaceContainerHighest : "#303136"
    property color dmsSurfaceVariant: Palette.surfaceVariant ? Palette.surfaceVariant : "#45474d"
    property color dmsPrimary: Palette.primary ? Palette.primary : "#8cb8ff"
    property color dmsPrimaryContainer: Palette.primaryContainer ? Palette.primaryContainer : "#2c4668"
    property color dmsOnPrimaryContainer: Palette.primaryContainerForeground ? Palette.primaryContainerForeground : "#f3f7ff"
    property color dmsOutline: Palette.outline ? Palette.outline : "#547197"
    property color dmsOutlineVariant: Palette.outlineVariant ? Palette.outlineVariant : "#45474d"
    property color dmsOnSurface: Palette.foreground ? Palette.foreground : "#f3f7ff"
    property color dmsMutedText: Palette.mutedForeground ? Palette.mutedForeground : "#9fb0c8"
    property color overviewTint: Palette.backgroundTint ? Palette.backgroundTint : "#1b1b1f"
    property color overviewAccent: Palette.primaryContainer ? Palette.primaryContainer : "#2c4668"
    readonly property var workspaceTargets: {
        var counts = {}
        var extras = []
        var maxWorkspaceId = Math.max(root.persistentWorkspaceCount, root.activeWorkspaceId)
        var values = Hyprland.toplevels ? Hyprland.toplevels.values : []

        if (values) {
            for (var i = 0; i < values.length; ++i) {
                var win = values[i]
                var info = win && win.lastIpcObject ? win.lastIpcObject : {}
                var workspace = info && info.workspace ? info.workspace : null
                var workspaceId = workspace && workspace.id !== undefined ? Number(workspace.id) : -1
                if (workspaceId < 1)
                    continue
                counts[workspaceId] = (counts[workspaceId] || 0) + 1
                if (workspaceId > maxWorkspaceId)
                    maxWorkspaceId = workspaceId
            }
        }

        for (var workspaceKey in counts) {
            var numericId = Number(workspaceKey)
            if (numericId > root.persistentWorkspaceCount && extras.indexOf(numericId) === -1)
                extras.push(numericId)
        }

        if (root.activeWorkspaceId > root.persistentWorkspaceCount && extras.indexOf(root.activeWorkspaceId) === -1)
            extras.push(root.activeWorkspaceId)

        extras.sort(function(a, b) { return a - b })

        var result = []
        for (var id = 1; id <= root.persistentWorkspaceCount; ++id) {
            result.push({
                id: id,
                label: String(id),
                count: counts[id] || 0,
                isNew: false
            })
        }

        for (var extraIndex = 0; extraIndex < extras.length; ++extraIndex) {
            var extraId = extras[extraIndex]
            result.push({
                id: extraId,
                label: String(extraId),
                count: counts[extraId] || 0,
                isNew: false
            })
        }

        result.push({
            id: Math.max(root.persistentWorkspaceCount + 1, maxWorkspaceId + 1),
            label: "+",
            count: 0,
            isNew: true
        })

        return result
    }

    function withAlpha(colorValue, alphaValue) {
        return Qt.rgba(colorValue.r, colorValue.g, colorValue.b, Math.max(0, Math.min(1, alphaValue)))
    }

    function highestWorkspaceId() {
        var maxId = Math.max(1, root.activeWorkspaceId)
        var values = Hyprland.toplevels ? Hyprland.toplevels.values : []
        if (!values)
            return maxId
        for (var i = 0; i < values.length; ++i) {
            var win = values[i]
            var info = win && win.lastIpcObject ? win.lastIpcObject : {}
            var workspace = info && info.workspace ? info.workspace : null
            var workspaceId = workspace && workspace.id !== undefined ? Number(workspace.id) : -1
            if (workspaceId > maxId)
                maxId = workspaceId
        }
        return maxId
    }

    function switchWorkspace(workspaceId) {
        if (workspaceId < 1)
            return
        Hyprland.dispatch(`workspace ${workspaceId}`)
    }

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    visible: isActive

    // LayerShell Configs
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: isActive ? 1 : 0
    WlrLayershell.namespace: "quickshell:expose"

    // --- IPC & EVENTS ---
    IpcHandler {
        target: "expose"
        function toggle(layout: string) {
            root.layoutAlgorithm = "smartgrid"
            root.toggleExpose()
        }

        function open(layout: string) {
            root.layoutAlgorithm = "smartgrid"
            if (root.isActive) return
            root.toggleExpose()
        }

        function close() {
            if (!root.isActive) return
            root.toggleExpose()
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(ev) {
            if (!root.isActive && ev.name !== "activespecial") return

            switch (ev.name) {
                case "openwindow":
                case "closewindow":
                case "changefloatingmode":
                case "movewindow":
                    Hyprland.refreshToplevels()
                    refreshThumbs()
                    return

                case "activespecial":
                    var dataStr = String(ev.data)
                    var namePart = dataStr.split(",")[0]
                    root.specialActive = (namePart.length > 0)
                    return
                case "workspacev2":
                    var wsData = String(ev.data).split(",")
                    var wsId = parseInt(wsData[0], 10)
                    if (!isNaN(wsId)) root.activeWorkspaceId = wsId
                    return

                default:
                    return
            }
        }
    }

    // Adaptive refresh: smoother on few windows, conservative on many.
    Timer {
        id: screencopyTimer
        interval: {
            if (!root.efficientMode) return 33
            var c = Math.max(1, root.thumbCount)
            if (c <= 3) return 34
            if (c <= 6) return 45
            if (c <= 10) return 60
            return 80
        }
        repeat: true
        // Keep non-live thumbnails static after initial capture; periodic recapture
        // was causing visible flicker on some compositors.
        running: false
        onTriggered: root.refreshThumbs()
    }


    function toggleExpose() {
        root.isActive = !root.isActive
        if (root.isActive) {
            root.lastLayoutAlgorithm = "smartgrid"
            root.refreshCursor = 0

            exposeArea.currentIndex = -1
            Hyprland.refreshToplevels()
            refreshThumbs(true)
        } else {
            root.animateWindows = false
            root.lastPositions = {}
            root.refreshCursor = 0
        }
    }

    function refreshThumbs(forceAll) {
        if (!root.isActive) return
        var total = winRepeater.count
        if (total <= 0) return

        function refreshAt(i) {
            var it = winRepeater.itemAt(i)
            if (it && it.visible && it.refreshThumb) it.refreshThumb()
        }

        if (forceAll === true || !root.efficientMode || total <= 6) {
            for (var i = 0; i < total; ++i) refreshAt(i)
            return
        }

        var focused = exposeArea.currentIndex
        var batch = Math.min(4, total)
        if (focused >= 0 && focused < total) {
            refreshAt(focused)
            batch = Math.max(1, batch - 1)
        }

        var done = 0
        var scan = 0
        while (done < batch && scan < total) {
            var idx = (root.refreshCursor + scan) % total
            scan += 1
            if (idx === focused) continue
            refreshAt(idx)
            done += 1
        }

        root.refreshCursor = (root.refreshCursor + batch) % total
    }

    function moveWindowToWorkspace(address, workspaceId) {
        if (!address || workspaceId < 1) return
        var addr = String(address).trim()
        if (!addr.startsWith("0x")) addr = "0x" + addr
        Hyprland.dispatch(`movetoworkspacesilent ${workspaceId},address:${addr}`)
        Qt.callLater(function() {
            Hyprland.refreshToplevels()
            Hyprland.refreshWorkspaces()
            root.refreshThumbs()
        })
    }

    // --- USER INTERFACE ---
    FocusScope {
        id: mainScope
        anchors.fill: parent
        focus: true

        Keys.onPressed: (event) => {
            if (!root.isActive) return

            if (event.key === Qt.Key_Escape) {
                root.toggleExpose()
                event.accepted = true
                return
            }

            const total = winRepeater.count
            if (total <= 0) return

            // Helper for horizontal navigation
            function moveSelectionHorizontal(delta) {
                var start = exposeArea.currentIndex
                for (var step = 1; step <= total; ++step) {
                    var candidate = (start + delta * step + total) % total
                    var it = winRepeater.itemAt(candidate)
                    if (it && it.visible) {
                        exposeArea.currentIndex = candidate
                        return
                    }
                }
            }

            // Helper for vertical navigation
            function moveSelectionVertical(dir) {
                var startIndex = exposeArea.currentIndex
                var currentItem = winRepeater.itemAt(startIndex)

                if (!currentItem || !currentItem.visible) {
                    moveSelectionHorizontal(dir > 0 ? 1 : -1)
                    return
                }

                var curCx = currentItem.x + currentItem.width  / 2
                var curCy = currentItem.y + currentItem.height / 2

                var bestIndex = -1
                var bestDy = 99999999
                var bestDx = 99999999

                for (var i = 0; i < total; ++i) {
                    var it = winRepeater.itemAt(i)
                    if (!it || !it.visible || i === startIndex) continue

                    var cx = it.x + it.width  / 2
                    var cy = it.y + it.height / 2
                    var dy = cy - curCy

                    // Direction filtering
                    if (dir > 0 && dy <= 0) continue
                    if (dir < 0 && dy >= 0) continue

                    var absDy = Math.abs(dy)
                    var absDx = Math.abs(cx - curCx)

                    // Search for nearest thumb (first in vertical, then horizontal distance)
                    if (absDy < bestDy || (absDy === bestDy && absDx < bestDx)) {
                        bestDy = absDy
                        bestDx = absDx
                        bestIndex = i
                    }
                }

                if (bestIndex >= 0) {
                    exposeArea.currentIndex = bestIndex
                }
            }

            if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
                moveSelectionHorizontal(1)
                event.accepted = true
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) {
                moveSelectionHorizontal(-1)
                event.accepted = true
            } else if (event.key === Qt.Key_Down) {
                moveSelectionVertical(1)
                event.accepted = true
            } else if (event.key === Qt.Key_Up) {
                moveSelectionVertical(-1)
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                var item = winRepeater.itemAt(exposeArea.currentIndex)
                if (item && item.activateWindow) {
                    item.activateWindow()
                    event.accepted = true
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: false
            z: -1
            onClicked: root.toggleExpose()
        }

        Rectangle {
            anchors.fill: parent
            z: -3
            color: root.withAlpha(root.overviewTint, 0.60)
        }

        Rectangle {
            anchors.fill: parent
            z: -2
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: root.withAlpha(root.overviewAccent, 0.10)
                }
                GradientStop {
                    position: 0.45
                    color: root.withAlpha(root.dmsSurface, 0.10)
                }
                GradientStop {
                    position: 1.0
                    color: root.withAlpha(root.overviewTint, 0.24)
                }
            }
        }

        Item {
            id: layoutContainer
            anchors.fill: parent
            anchors.margins: root.edgePadding

                Item {
                    id: layoutRoot
                    anchors.fill: parent
                    anchors.margins: 0
                    property int sectionSpacing: 12

                Item {
                    id: stageFrame
                    width: Math.min(layoutRoot.width * 0.9, root.stageMaxWidth)
                    anchors.horizontalCenter: layoutRoot.horizontalCenter
                    anchors.top: layoutRoot.top
                    anchors.topMargin: 18
                    anchors.bottom: workspaceDock.top
                    anchors.bottomMargin: 26
                    z: 10

                    // thumbs area
                    Item {
                        id: exposeArea
                        anchors.fill: parent
                        anchors.margins: 0
                        property int currentIndex: 0

                        ScriptModel {
                            id: windowLayoutModel

                            property int areaW: exposeArea.width
                            property int areaH: exposeArea.height
                            property string algo: root.lastLayoutAlgorithm
                            property var rawToplevels: Hyprland.toplevels.values

                            values: {
                                // Bailout on wrong screen size
                                if (areaW <= 0 || areaH <= 0) return []

                                var windowList = []
                                var idx = 0

                                if (!rawToplevels) return []

                                for (var it of rawToplevels) {
                                    var w = it
                                    var clientInfo = w && w.lastIpcObject ? w.lastIpcObject : {}
                                    var workspace = clientInfo && clientInfo.workspace ? clientInfo.workspace : null
                                    var workspaceId = workspace && workspace.id !== undefined ? workspace.id : undefined

                                    // Filter invalid workspace or offscreen windows
                                    if (workspaceId === undefined || workspaceId === null) continue
                                    var size = clientInfo && clientInfo.size ? clientInfo.size : [0, 0]
                                    var at = clientInfo && clientInfo.at ? clientInfo.at : [-1000, -1000]
                                    if (at[1] + size[1] <= 0) continue

                                    windowList.push({
                                        win: w,
                                        clientInfo: clientInfo,
                                        workspaceId: workspaceId,
                                        width: size[0],
                                        height: size[1],
                                        originalIndex: idx++,
                                        lastIpcObject: w.lastIpcObject
                                    })
                                }

                                windowList.sort(function(a, b) {
                                    var activeA = Number(a.workspaceId) === root.activeWorkspaceId ? 0 : 1
                                    var activeB = Number(b.workspaceId) === root.activeWorkspaceId ? 0 : 1
                                    if (activeA !== activeB)
                                        return activeA - activeB
                                    if (a.workspaceId < b.workspaceId) return -1
                                    if (a.workspaceId > b.workspaceId) return 1
                                    if (a.originalIndex < b.originalIndex) return -1
                                    if (a.originalIndex > b.originalIndex) return 1
                                    return 0
                                })

                                return LayoutsManager.doLayout(algo, windowList, areaW, areaH)
                            }
                        }

                        Repeater {
                            id: winRepeater
                            model: windowLayoutModel

                            delegate: WindowThumbnail {
                                hWin: modelData.win
                                wHandle: hWin.wayland
                                winKey: String(hWin.address)
                                thumbW: modelData.width
                                thumbH: modelData.height
                                clientInfo: hWin.lastIpcObject
                                targetX: (modelData && modelData.x !== undefined) ? modelData.x : -1000
                                targetY: (modelData && modelData.y !== undefined) ? modelData.y : -1000
                                targetZ: (visible && (exposeArea.currentIndex === index)) ? 1000 : ((modelData && modelData.zIndex) ? modelData.zIndex : 0)
                                targetRotation: 0
                                workspaceId: (modelData && modelData.workspaceId) ? modelData.workspaceId : ((hWin && hWin.workspace) ? hWin.workspace.id : -1)
                                hovered: visible && (exposeArea.currentIndex === index)
                                moveCursorToActiveWindow: root.moveCursorToActiveWindow
                                exposeRoot: root
                            }
                        }
                    }
                }

                Item {
                    id: workspaceDock
                    width: Math.min(layoutRoot.width * 0.52, 560)
                    anchors.horizontalCenter: layoutRoot.horizontalCenter
                    anchors.bottom: layoutRoot.bottom
                    anchors.bottomMargin: 12
                    height: 94
                    z: 40

                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        spacing: 10

                        Row {
                            id: workspaceRow
                            spacing: 18
                            anchors.horizontalCenter: parent.horizontalCenter

                            Repeater {
                                model: root.workspaceTargets.length

                                delegate: Item {
                                    readonly property var modelData: root.workspaceTargets[index]

                                    property int targetWorkspaceId: Number(modelData.id)
                                    property string targetLabel: String(modelData.label)
                                    property bool isNewTarget: Boolean(modelData.isNew)
                                    property bool isActiveTarget: !isNewTarget && root.activeWorkspaceId === targetWorkspaceId
                                    property bool isDropTarget: root.draggingTargetWorkspace === targetWorkspaceId
                                    property bool isSourceTarget: root.draggingFromWorkspace === targetWorkspaceId
                                    property bool isOccupied: Number(modelData.count || 0) > 0

                                    width: targetPill.width
                                    height: targetPill.height

                                    Rectangle {
                                        id: targetPill
                                        width: isDropTarget ? 84 : (isActiveTarget ? 48 : 46)
                                        height: 46
                                        radius: 23
                                        color: isDropTarget
                                            ? root.dmsPrimaryContainer
                                            : isActiveTarget
                                                ? root.dmsPrimaryContainer
                                                : (isNewTarget
                                                    ? root.withAlpha(root.dmsSurface, 0.30)
                                                    : (isOccupied
                                                        ? root.withAlpha(root.dmsSurfaceVariant, 0.86)
                                                        : root.withAlpha(root.dmsSurface, 0.56)))
                                        border.width: 1
                                        border.color: isDropTarget
                                            ? root.dmsPrimary
                                            : isActiveTarget
                                                ? root.withAlpha(root.dmsPrimary, 0.82)
                                                : (isNewTarget
                                                    ? root.withAlpha(root.dmsPrimary, 0.78)
                                                    : (isOccupied
                                                        ? root.withAlpha(root.dmsPrimary, 0.34)
                                                        : root.withAlpha(root.dmsOutline, 0.44)))

                                        Behavior on width {
                                            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                                        }

                                        Behavior on color {
                                            ColorAnimation { duration: 150 }
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: targetLabel
                                            color: isDropTarget
                                                ? root.dmsOnPrimaryContainer
                                                : isActiveTarget
                                                    ? root.dmsOnPrimaryContainer
                                                    : (isNewTarget
                                                        ? root.dmsPrimary
                                                        : (isOccupied
                                                            ? root.dmsOnSurface
                                                            : root.dmsMutedText))
                                            font.pixelSize: 19
                                            font.bold: isActiveTarget || isDropTarget
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.switchWorkspace(targetWorkspaceId)
                                    }

                                    DropArea {
                                        anchors.fill: parent

                                        onEntered: root.draggingTargetWorkspace = targetWorkspaceId
                                        onExited: {
                                            if (root.draggingTargetWorkspace === targetWorkspaceId)
                                                root.draggingTargetWorkspace = -1
                                        }
                                        onDropped: {
                                            var source = drag.source
                                            if (!source || !source.windowAddress)
                                                return
                                            source.dropHandled = true
                                            root.moveWindowToWorkspace(source.windowAddress, targetWorkspaceId)
                                            if (isNewTarget)
                                                root.switchWorkspace(targetWorkspaceId)
                                            root.draggingTargetWorkspace = -1
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Workspaces"
                            color: root.withAlpha(root.dmsMutedText, 0.92)
                            font.pixelSize: 12
                        }
                    }
                }

            }
        }
    }
}
