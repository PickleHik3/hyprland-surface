# Troubleshooting

## Keyboard does not auto show or hide

Check the runtime processes:

```bash
pgrep -af 'fcitx5|wvkbd-deskintl-custom|fcitx-wvkbd-auto'
```

Check the state directory:

```bash
ls -la "/run/user/$UID/wvkbd-custom"
```

Expected auto-mode state:

- `fcitx-wvkbd-auto.sh` is running
- `disabled` is absent
- `visible` appears while Fcitx has a focused input context

Re-enable auto mode:

```bash
~/.config/hypr/apps/wvkbd/scripts/auto-show-wvkbd.sh
```

Disable keyboard auto mode:

```bash
~/.config/hypr/apps/wvkbd/scripts/disable-wvkbd.sh
```

## DMS still shows old plugin variants

Check persisted plugin settings:

```bash
rg -n '"Home"|"action": "home"' ~/.config/DankMaterialShell/plugin_settings.json
```

The current plugin also sanitizes stored variants on load, but stale settings
can remain if DMS has not been restarted after installing the new plugin.

Restart DMS:

```bash
dms restart
```

## Back button does not work

The DMS back variant sends `XF86Back` through Hyprland:

```bash
hyprctl dispatch sendshortcut ,XF86Back,activewindow
```

If that command does not work in an app, the app likely does not handle the
standard back key event.
