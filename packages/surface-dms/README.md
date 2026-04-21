# surface-dms

DMS plugin repository for the Surface-oriented Hyprland setup.

## Plugin

`Surface Tablet Controls` adds:

- a DankBar button for `qs-hyprview` recent apps
- a DankBar button for `wvkbd` keyboard toggle
- a DankBar button for universal back
- default separate widget variants for:
  - `qs-hyprview`
  - keyboard toggle
  - universal back

## Default paths

- `qs-hyprview`: `~/.config/hypr/apps/qs-hyprview`
- `wvkbd`: `~/.config/hypr/apps/wvkbd`

## Install

1. Clone this repository into the DMS plugin directory:
   - `mkdir -p ~/.config/DankMaterialShell/plugins`
   - `git clone https://github.com/PickleHik3/surface-dms ~/.config/DankMaterialShell/plugins/surface-dms`
2. Open DMS Settings and go to `Plugins`.
3. Click `Scan for Plugins`.
4. Enable `Surface Tablet Controls`.
5. Open the plugin settings and click `Create Missing Default Variants`.
6. Add the widgets you want to your DankBar layout.
7. Restart the shell with `dms restart`.

## Default variants

The plugin can be used in two ways:

- one grouped widget with recent apps, keyboard toggle, and back
- separate variants that show up as their own DankBar items:
  - `Recent Apps`
  - `Keyboard Toggle`
  - `Back`

The `Back` variant sends `XF86Back` through Hyprland's `sendshortcut` dispatcher.

## Files

- [plugin.json](plugin.json)
- [Main.qml](surface-tablet-controls/Main.qml)
- [Settings.qml](surface-tablet-controls/Settings.qml)

## Notes

- This repository now follows the DMS plugin format directly.
- For plugin registry submission, keep `plugin.json`, this README, and a screenshot in the repository root.
