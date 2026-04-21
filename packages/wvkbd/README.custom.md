# Custom wvkbd (deskintl)

Patched `wvkbd-deskintl` source and runnable scripts for Hyprland/fcitx5.

## Layout changes

- Removed `Cmp` key left of `Caps` (Latin full layout).
- Removed `Cmp` key left of `Caps` (Cyrillic full layout).
- Removed keyboard-toggle key (`⌨`) in the special layer row.

## Folder structure

- `src/` upstream source + patched `layout.deskintl.h`
- `bin/` compiled binary (`wvkbd-deskintl-custom`)
- `scripts/` runtime helpers (start/show/hide/restart)
- `patches/` patch notes and references
- `notes/` troubleshooting notes

## Build

```bash
cd ~/.config/hypr/wvkbd
./build-custom.sh
```

## Runtime scripts

```bash
~/.config/hypr/wvkbd/scripts/start-wvkbd.sh
~/.config/hypr/wvkbd/scripts/show-wvkbd.sh
~/.config/hypr/wvkbd/scripts/hide-wvkbd.sh
```
