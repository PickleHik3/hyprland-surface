# hyprland-surface

Packaged Surface Pro 7 Hyprland tablet setup around Dank Material Shell.

This repository vendors the current working pieces together so the setup can be
installed from one checkout instead of rebuilding from several separate repos.

## Layout

```text
packages/
  surface-dms/      DMS plugin with Back, Keyboard Toggle, and Recent Apps
  qs-hyprview/      Quickshell recent-apps overview
  wvkbd/            Patched wvkbd source, scripts, and Fcitx integration files
  hypr/             Hyprland config snapshot
  sddm/             SDDM silent-theme tablet config
systemd/user/       User services for wvkbd and the Fcitx focus watcher
docs/               Notes and troubleshooting
install.sh          Installs the packaged setup into the live config paths
uninstall.sh        Removes app packages and user services
```

`sync-live.sh` is intentionally ignored and not part of the online copy. Keep it
local if you want a fast developer sync script.

## Dependencies

Install the base packages first:

```bash
sudo pacman -S --needed \
  sddm qt5-virtualkeyboard \
  fcitx5 fcitx5-gtk fcitx5-qt fcitx5-configtool \
  git cmake base-devel rsync
```

Install separately as needed:

- Dank Material Shell, using the official DMS install method
- `sddm-silent-theme`
- `iio-hyprland`
- `hyprgrass`
- `linux-surface`, if this is a Surface device

## Install

From the repo root:

```bash
./install.sh
```

The installer copies:

- `packages/wvkbd` to `~/.config/hypr/apps/wvkbd`
- `packages/qs-hyprview` to `~/.config/hypr/apps/qs-hyprview`
- `packages/surface-dms` to `~/.config/DankMaterialShell/plugins/surface-dms`
- `packages/hypr` to `~/.config/hypr`
- Fcitx environment and virtual keyboard config files to `~/.config`
- user services to `~/.config/systemd/user`

It also builds the custom `wvkbd` binary and enables:

- `qs-hyprview.service`
- `wvkbd.service`
- `fcitx-wvkbd-auto.service`

If this is the first time installing the Fcitx environment files, restart the
user session after installation.

## DMS Plugin

After install:

1. Open DMS settings.
2. Go to `Plugins`.
3. Click `Scan for Plugins`.
4. Enable `Surface Tablet Controls`.
5. Open its settings and click `Create Missing Default Variants`.
6. Add the variants you want in DankBar settings.

Recommended variants:

- `Recent Apps`
- `Keyboard Toggle`
- `Back`

The old `Home` variant is no longer part of the plugin.

## Keyboard Model

`wvkbd` starts hidden. Fcitx focus drives show/hide through
`fcitx-wvkbd-auto.service`, which watches Fcitx input-context focus and calls
the existing `show-wvkbd.sh` and `hide-wvkbd.sh` scripts.

The DMS keyboard button only switches between two user states:

- auto mode: clears the disabled flag, starts the watcher, and force-shows once
- disabled mode: stops the watcher, hides the keyboard, and blocks show requests

Icon state is based on files in `/run/user/$UID/wvkbd-custom`:

- no flag: `keyboard`
- `visible`: `keyboard_hide`
- `disabled`: `keyboard_off`

## SDDM

SDDM files are packaged but not installed automatically because they write to
system paths. Install them manually:

```bash
sudo cp packages/sddm/sddm.conf /etc/sddm.conf
sudo install -d -m 0755 /usr/share/sddm/themes/silent/configs
sudo cp packages/sddm/metadata.desktop /usr/share/sddm/themes/silent/metadata.desktop
sudo cp packages/sddm/catppuccin-mocha-tablet.conf /usr/share/sddm/themes/silent/configs/catppuccin-mocha-tablet.conf
```

## Verify

```bash
systemctl --user status qs-hyprview.service --no-pager
systemctl --user status wvkbd.service --no-pager
systemctl --user status fcitx-wvkbd-auto.service --no-pager
pgrep -af 'fcitx5|wvkbd-deskintl-custom|fcitx-wvkbd-auto|quickshell|dms'
dms ipc plugins status surfaceTabletControls
```

## Uninstall

```bash
./uninstall.sh
```

The uninstaller removes app packages and user services. It intentionally leaves
Hyprland config, Fcitx config, DMS settings, and SDDM system files in place.
