import QtQuick

QtObject {
    readonly property color background: "{{colors.background.default.hex}}"
    readonly property color surface: "{{colors.surface.default.hex}}"
    readonly property color surfaceContainer: "{{colors.surface_container.default.hex}}"
    readonly property color surfaceContainerHigh: "{{colors.surface_container_high.default.hex}}"
    readonly property color primary: "{{colors.primary.default.hex}}"
    readonly property color primaryContainer: "{{colors.primary_container.default.hex}}"
    readonly property color secondaryContainer: "{{colors.secondary_container.default.hex}}"
    readonly property color outline: "{{colors.outline.default.hex}}"
    readonly property color surfaceText: "{{colors.on_surface.default.hex}}"
    readonly property color surfaceVariantText: "{{colors.on_surface_variant.default.hex}}"
    readonly property color primaryContainerText: "{{colors.on_primary_container.default.hex}}"
    readonly property real backdropBlur: 1.0
    readonly property real backdropBlurMax: 96
    readonly property real backdropSaturation: 0.62
    readonly property real backdropBrightness: -0.28
    readonly property real glassBaseOpacity: 0.84
    readonly property real glassAccentOpacity: 0.34
    readonly property real glassDimOpacity: 0.32
}
