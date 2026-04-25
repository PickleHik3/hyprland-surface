pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property color surface: "#121212"
    property color surfaceContainerLow: "#1b1b1f"
    property color surfaceContainerHigh: "#25262b"
    property color surfaceContainerHighest: "#303136"
    property color surfaceVariant: "#45474d"
    property color primary: "#8cb8ff"
    property color primaryContainer: "#2c4668"
    property color primaryContainerForeground: "#f3f7ff"
    property color outline: "#547197"
    property color outlineVariant: "#45474d"
    property color foreground: "#f3f7ff"
    property color mutedForeground: "#9fb0c8"
    property color backgroundTint: "#1b2433"
    property color accent: "#2c4668"

    readonly property string themeFilePath: resolvedPath(Qt.resolvedUrl("../theme.json"))

    function resolvedPath(url) {
        var text = String(url || "")
        if (text.indexOf("file://") === 0)
            return decodeURIComponent(text.slice(7))
        return text
    }

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\"'\"'") + "'"
    }

    function applyThemeJson(text) {
        if (!text || text.trim().length === 0)
            return

        try {
            const data = JSON.parse(text)
            if (data.surface)
                root.surface = data.surface
            if (data.surfaceContainerLow)
                root.surfaceContainerLow = data.surfaceContainerLow
            if (data.surfaceContainerHigh)
                root.surfaceContainerHigh = data.surfaceContainerHigh
            if (data.surfaceContainerHighest)
                root.surfaceContainerHighest = data.surfaceContainerHighest
            if (data.surfaceVariant)
                root.surfaceVariant = data.surfaceVariant
            if (data.primary)
                root.primary = data.primary
            if (data.primaryContainer)
                root.primaryContainer = data.primaryContainer
            if (data.onPrimaryContainer)
                root.primaryContainerForeground = data.onPrimaryContainer
            if (data.outline)
                root.outline = data.outline
            if (data.outlineVariant)
                root.outlineVariant = data.outlineVariant
            if (data.foreground)
                root.foreground = data.foreground
            if (data.onSurfaceVariant)
                root.mutedForeground = data.onSurfaceVariant
            if (data.backgroundTint)
                root.backgroundTint = data.backgroundTint
            if (data.accent)
                root.accent = data.accent
        } catch (error) {
            console.log("qs-hyprview palette parse failed:", error)
        }
    }

    function reload() {
        themeReader.running = false
        themeReader.exec({
            command: [
                "bash",
                "-lc",
                "if [[ -f " + shellQuote(themeFilePath) + " ]]; then cat " + shellQuote(themeFilePath) + "; fi"
            ]
        })
    }

    Component.onCompleted: reload()

    Process {
        id: themeReader

        running: false

        stdout: StdioCollector {
            onStreamFinished: root.applyThemeJson(text)
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: root.reload()
    }
}
