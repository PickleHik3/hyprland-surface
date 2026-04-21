# wvkbd

Patched `wvkbd-deskintl` plus the helper scripts used by my Hyprland + Fcitx5 setup.

## What changed

- removed the `Cmp` key left of `Caps` in the Latin full layout
- removed the `Cmp` key left of `Caps` in the Cyrillic full layout
- removed the keyboard toggle key (`⌨`) in the special layer row

## Install

Clone into the default app path:

```bash
mkdir -p ~/.config/hypr/apps
cd ~/.config/hypr/apps
git clone https://github.com/PickleHik3/wvkbd.git
```

Build the custom binary:

```bash
cd ~/.config/hypr/apps/wvkbd
./build-custom.sh
```

## Runtime paths

- startup: `~/.config/hypr/apps/wvkbd/scripts/start-wvkbd.sh`
- auto mode: `~/.config/hypr/apps/wvkbd/scripts/auto-show-wvkbd.sh`
- Fcitx focus watcher: `~/.config/hypr/apps/wvkbd/scripts/fcitx-wvkbd-auto.sh`
- force show: `~/.config/hypr/apps/wvkbd/scripts/show-wvkbd.sh`
- force hide: `~/.config/hypr/apps/wvkbd/scripts/hide-wvkbd.sh`
- disable: `~/.config/hypr/apps/wvkbd/scripts/disable-wvkbd.sh`

## Fcitx5 integration files

This repo also ships the Fcitx-related config files that belong to the keyboard setup:

- `integration/environment.d/10-fcitx.conf`
- `integration/fcitx5/conf/virtualkeyboardadapter.conf`

Install them with:

```bash
mkdir -p ~/.config/environment.d
cp integration/environment.d/10-fcitx.conf ~/.config/environment.d/10-fcitx.conf

mkdir -p ~/.config/fcitx5/conf
cp integration/fcitx5/conf/virtualkeyboardadapter.conf ~/.config/fcitx5/conf/virtualkeyboardadapter.conf
```

## Noctalia theming

This repo also contains the Noctalia user-template integration used by the live setup.

- template source: `noctalia/theme-template.sh`
- generated output path used by the setup: `~/.config/hypr/apps/wvkbd/generated/noctalia-theme.sh`

## Layout

- `src/` patched source tree
- `bin/` built binary
- `scripts/` runtime helpers
- `integration/` Fcitx integration files
- `notes/` integration notes
