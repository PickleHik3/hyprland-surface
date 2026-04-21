import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    pluginId: "surfaceTabletControls"
    layerNamespacePlugin: "surface-tablet-controls"

    property string variantId: ""
    property var variantData: null
    property var popoutService: null
    property string lastAction: ""
    property string lastError: ""
    pillClickAction: isVariant ? runVariantAction : null
    pillRightClickAction: null

    readonly property var effectiveVariantData: {
        if (variantData)
            return variantData;
        if (!variantId || !variants)
            return null;
        for (let i = 0; i < variants.length; i++) {
            const item = variants[i];
            if (item && item.id === variantId)
                return item;
        }
        return null;
    }
    readonly property bool isVariant: variantId !== ""
    readonly property string actionKind: effectiveVariantData && effectiveVariantData.action ? effectiveVariantData.action : "menu"
    readonly property string variantIcon: effectiveVariantData && effectiveVariantData.icon ? effectiveVariantData.icon : "widgets"
    readonly property string recentAppsPath: pluginData.recentAppsPath || "$HOME/.config/hypr/apps/qs-hyprview"
    readonly property string keyboardAutoScript: pluginData.keyboardAutoScript || "$HOME/.config/hypr/apps/wvkbd/scripts/auto-show-wvkbd.sh"
    readonly property string keyboardDisableScript: pluginData.keyboardDisableScript || "$HOME/.config/hypr/apps/wvkbd/scripts/disable-wvkbd.sh"
    readonly property string keyboardDisabledFlag: String(Quickshell.env("XDG_RUNTIME_DIR") || "/run/user/" + String(Quickshell.env("UID") || "")) + "/wvkbd-custom/disabled"
    readonly property string keyboardVisibleFlag: String(Quickshell.env("XDG_RUNTIME_DIR") || "/run/user/" + String(Quickshell.env("UID") || "")) + "/wvkbd-custom/visible"
    readonly property int actionButtonSize: Math.max(30, iconSize + Theme.spacingS)
    readonly property bool isKeyboardAction: actionKind === "keyboardToggle"
    property bool keyboardDisabled: false
    property bool keyboardVisible: false

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\"'\"'") + "'";
    }

    function expandHome(value) {
        const home = Quickshell.env("HOME") || "";
        const text = String(value || "");
        if (!home)
            return text;
        if (text === "$HOME")
            return home;
        if (text.indexOf("$HOME/") === 0)
            return home + text.slice(5);
        return text;
    }

    function createDefaultVariants(forceCreate) {
        if (!pluginService)
            return;

        const defaults = [
            { name: "Recent Apps", action: "recentApps", icon: "square" },
            { name: "Keyboard Toggle", action: "keyboardToggle", icon: "keyboard" },
            { name: "Back", action: "back", icon: "arrow_back_ios" }
        ];
        const existingActions = {};

        for (let i = 0; i < variants.length; i++) {
            const item = variants[i];
            if (item && item.action)
                existingActions[item.action] = true;
        }

        for (let i = 0; i < defaults.length; i++) {
            const item = defaults[i];
            if (!forceCreate && existingActions[item.action])
                continue;
            createVariant(item.name, item);
        }
    }

    function sanitizeStoredVariants() {
        if (!pluginService || !pluginData || !pluginData.variants || !Array.isArray(pluginData.variants))
            return;

        const defaultsByAction = {
            recentApps: { name: "Recent Apps", icon: "square" },
            keyboardToggle: { name: "Keyboard Toggle", icon: "keyboard" },
            back: { name: "Back", icon: "arrow_back_ios" }
        };
        const seenActions = {};
        const sanitized = [];
        let changed = false;

        for (let i = 0; i < pluginData.variants.length; i++) {
            const item = pluginData.variants[i];
            if (!item || !item.action || !defaultsByAction[item.action]) {
                changed = true;
                continue;
            }
            if (seenActions[item.action]) {
                changed = true;
                continue;
            }

            seenActions[item.action] = true;
            const defaults = defaultsByAction[item.action];
            const normalized = {
                id: item.id,
                action: item.action,
                name: item.name || defaults.name,
                icon: defaults.icon
            };

            if (item.name !== normalized.name || item.icon !== normalized.icon)
                changed = true;

            sanitized.push(normalized);
        }

        if (changed)
            pluginService.savePluginData(pluginId, "variants", sanitized);
    }

    function ensureDefaultVariants() {
        if (!pluginService)
            return;

        createDefaultVariants(false);
        if (!pluginData.defaultVariantsCreated)
            pluginService.savePluginData(pluginId, "defaultVariantsCreated", true);
    }

    function runShell(script, actionLabel) {
        root.lastAction = actionLabel || "";
        root.lastError = "";
        executor.exec({
            command: ["bash", "-lc", script]
        });
    }

    function runCommand(args, actionLabel) {
        root.lastAction = actionLabel || "";
        root.lastError = "";
        executor.exec({
            command: args
        });
    }

    function runVariantAction() {
        if (actionKind === "recentApps")
            openRecentApps();
        else if (actionKind === "keyboardToggle")
            keyboardButtonAction();
        else if (actionKind === "back")
            universalBack();
        else
            openRecentApps();
    }

    function openRecentApps() {
        runCommand([
            "/usr/bin/quickshell",
            "ipc",
            "-p",
            expandHome(recentAppsPath),
            "call",
            "expose",
            "open",
            "smartgrid"
        ], "Recent apps");
    }

    function keyboardIconName() {
        if (keyboardDisabled)
            return "keyboard_off";
        if (keyboardVisible)
            return "keyboard_hide";
        return "keyboard";
    }

    function keyboardButtonAction() {
        if (keyboardDisabled || !keyboardVisible) {
            runCommand([expandHome(keyboardAutoScript)], "Keyboard auto+show");
            return;
        }
        runCommand([expandHome(keyboardDisableScript)], "Keyboard disable");
    }

    function refreshKeyboardState() {
        keyboardStateProbe.running = false;
        keyboardStateProbe.exec({
            command: [
                "bash",
                "-lc",
                [
                    "if [[ -f " + shellQuote(keyboardDisabledFlag) + " ]]; then",
                    "  printf disabled",
                    "elif [[ -f " + shellQuote(keyboardVisibleFlag) + " ]]; then",
                    "  printf visible",
                    "else",
                    "  printf hidden",
                    "fi"
                ].join("\n")
            ]
        });
    }

    function universalBack() {
        if (popoutService && popoutService.controlCenterPopout && popoutService.controlCenterPopout.shouldBeVisible) {
            popoutService.closeControlCenter();
            root.lastAction = "Back";
            root.lastError = "";
            return;
        }
        if (popoutService && popoutService.notificationCenterPopout && popoutService.notificationCenterPopout.shouldBeVisible) {
            popoutService.closeNotificationCenter();
            root.lastAction = "Back";
            root.lastError = "";
            return;
        }
        if (popoutService && popoutService.appDrawerPopout && popoutService.appDrawerPopout.shouldBeVisible) {
            popoutService.closeAppDrawer();
            root.lastAction = "Back";
            root.lastError = "";
            return;
        }
        if (popoutService && popoutService.processListPopout && popoutService.processListPopout.shouldBeVisible) {
            popoutService.closeProcessList();
            root.lastAction = "Back";
            root.lastError = "";
            return;
        }
        if (popoutService && popoutService.dankDashPopout && popoutService.dankDashPopout.dashVisible) {
            popoutService.closeDankDash();
            root.lastAction = "Back";
            root.lastError = "";
            return;
        }
        if (popoutService && popoutService.settingsModal && (popoutService.settingsModal.visible || popoutService.settingsModal.shouldBeVisible)) {
            popoutService.closeSettings();
            root.lastAction = "Back";
            root.lastError = "";
            return;
        }
        if (popoutService && popoutService.clipboardHistoryModal && (popoutService.clipboardHistoryModal.visible || popoutService.clipboardHistoryModal.shouldBeVisible)) {
            popoutService.clipboardHistoryModal.close();
            root.lastAction = "Back";
            root.lastError = "";
            return;
        }
        if (popoutService && popoutService.dankLauncherV2Modal && (popoutService.dankLauncherV2Modal.spotlightOpen || popoutService.dankLauncherV2Modal.visible)) {
            popoutService.closeDankLauncherV2();
            root.lastAction = "Back";
            root.lastError = "";
            return;
        }
        if (popoutService && popoutService.powerMenuModal && (popoutService.powerMenuModal.visible || popoutService.powerMenuModal.shouldBeVisible)) {
            popoutService.powerMenuModal.close();
            root.lastAction = "Back";
            root.lastError = "";
            return;
        }

        const backScript = [
            "hyprctl dispatch sendshortcut ,XF86Back,activewindow >/dev/null 2>&1 || hyprctl dispatch sendshortcut ,XF86Back >/dev/null 2>&1 || true"
        ].join("\n");
        runShell(backScript, "Back");
    }

    Component.onCompleted: {
        Qt.callLater(root.sanitizeStoredVariants);
        Qt.callLater(root.ensureDefaultVariants);
        Qt.callLater(root.refreshKeyboardState);
    }

    onPluginServiceChanged: {
        Qt.callLater(root.sanitizeStoredVariants);
        Qt.callLater(root.ensureDefaultVariants);
    }

    horizontalBarPill: Component {
        Item {
            implicitWidth: root.isVariant ? variantButton.width : groupedRow.implicitWidth
            implicitHeight: root.actionButtonSize

            ActionButton {
                id: variantButton
                visible: root.isVariant
                buttonSize: root.actionButtonSize
                iconName: root.actionKind === "recentApps" ? "square" : root.isKeyboardAction ? root.keyboardIconName() : root.actionKind === "back" ? "arrow_back_ios" : root.variantIcon
                iconColor: root.actionKind === "recentApps" ? Theme.primary : root.isKeyboardAction ? (root.keyboardDisabled ? Theme.surfaceVariantText : Theme.primary) : Theme.surfaceText
                backgroundColor: root.isKeyboardAction && !root.keyboardDisabled ? Theme.surfaceContainerLow : "transparent"
                indicatorVisible: false
                onClicked: root.runVariantAction()
            }

            Row {
                id: groupedRow
                visible: !root.isVariant
                spacing: Theme.spacingXS

                ActionButton {
                    buttonSize: root.actionButtonSize
                    iconName: "square"
                    iconColor: Theme.primary
                    onClicked: root.openRecentApps()
                }

                ActionButton {
                    buttonSize: root.actionButtonSize
                    iconName: root.keyboardIconName()
                    iconColor: root.keyboardDisabled ? Theme.surfaceVariantText : Theme.primary
                    backgroundColor: root.keyboardDisabled ? "transparent" : Theme.surfaceContainerLow
                    indicatorVisible: false
                    onClicked: root.keyboardButtonAction()
                }

                ActionButton {
                    buttonSize: root.actionButtonSize
                    iconName: "arrow_back_ios"
                    iconColor: Theme.surfaceText
                    onClicked: root.universalBack()
                }
            }
        }
    }

    verticalBarPill: Component {
        Item {
            implicitWidth: root.actionButtonSize
            implicitHeight: root.isVariant ? variantButton.height : groupedColumn.implicitHeight

            ActionButton {
                id: variantButton
                visible: root.isVariant
                buttonSize: root.actionButtonSize
                iconName: root.actionKind === "recentApps" ? "square" : root.isKeyboardAction ? root.keyboardIconName() : root.actionKind === "back" ? "arrow_back_ios" : root.variantIcon
                iconColor: root.actionKind === "recentApps" ? Theme.primary : root.isKeyboardAction ? (root.keyboardDisabled ? Theme.surfaceVariantText : Theme.primary) : Theme.surfaceText
                backgroundColor: root.isKeyboardAction && !root.keyboardDisabled ? Theme.surfaceContainerLow : "transparent"
                indicatorVisible: false
                onClicked: root.runVariantAction()
            }

            Column {
                id: groupedColumn
                visible: !root.isVariant
                spacing: Theme.spacingXS

                ActionButton {
                    buttonSize: root.actionButtonSize
                    iconName: "square"
                    iconColor: Theme.primary
                    onClicked: root.openRecentApps()
                }

                ActionButton {
                    buttonSize: root.actionButtonSize
                    iconName: root.keyboardIconName()
                    iconColor: root.keyboardDisabled ? Theme.surfaceVariantText : Theme.primary
                    backgroundColor: root.keyboardDisabled ? "transparent" : Theme.surfaceContainerLow
                    indicatorVisible: false
                    onClicked: root.keyboardButtonAction()
                }

                ActionButton {
                    buttonSize: root.actionButtonSize
                    iconName: "arrow_back_ios"
                    iconColor: Theme.surfaceText
                    onClicked: root.universalBack()
                }
            }
        }
    }

    Process {
        id: executor

        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim().length > 0)
                    console.log("SurfaceTabletControls:", text.trim());
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text && text.trim().length > 0) {
                    root.lastError = text.trim();
                    ToastService.showError("Surface Tablet Controls", root.lastError);
                }
            }
        }

        onExited: exitCode => {
            if (root.lastAction.indexOf("Keyboard") === 0)
                root.refreshKeyboardState();
            if (exitCode !== 0 && !root.lastError) {
                root.lastError = "Command failed with exit code " + exitCode;
                ToastService.showError("Surface Tablet Controls", root.lastError);
            }
        }
    }

    Process {
        id: keyboardStateProbe

        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const state = text.trim();
                if (state === "disabled") {
                    root.keyboardDisabled = true;
                    root.keyboardVisible = false;
                } else if (state === "visible") {
                    root.keyboardDisabled = false;
                    root.keyboardVisible = true;
                } else if (state === "hidden") {
                    root.keyboardDisabled = false;
                    root.keyboardVisible = false;
                }
            }
        }
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        onTriggered: root.refreshKeyboardState()
    }
}
