# hyprland-surface

This repo is the part of my Surface Pro 7 setup that makes Hyprland usable as a touch-first desktop.

## What is in this repo

- `hypr/hyprland.conf`: Hyprland config with Hyprgrass touch gestures
- `environment.d/10-fcitx.conf`: input method environment variables
- `fcitx5/conf/virtualkeyboardadapter.conf`: tells Fcitx5 how to show and hide the keyboard
- `wvkbd-custom/`: patched `wvkbd-deskintl` build and helper scripts
- `systemd-user/qs-hyprview.service`: starts the Quickshell overview
- `sddm/`: SDDM theme files I use on this tablet

## What this setup does

- uses `linux-surface` so the Surface hardware works properly
- runs Hyprland with touch gestures through Hyprgrass
- uses `fcitx5` plus a patched `wvkbd` for the on-screen keyboard
- starts `qs-hyprview` as a Quickshell overview

## Before you start

This was built on EndeavourOS, which is Arch-based. The current live machine is a Microsoft Surface Pro 7 with:

- Intel i5
- 8 GB RAM
- 128 GB storage

You can use plain Arch if you prefer, but the package steps below assume an Arch-based system.

## 1. Install the base system

Install EndeavourOS without a desktop environment, then boot into a TTY.

- https://endeavouros.com/

## 2. Install the `linux-surface` kernel

Follow the official guide:

- https://github.com/linux-surface/linux-surface

Reboot once the kernel is installed and make sure you are using it.

## 3. Install the main packages

```bash
sudo pacman -S --needed \
  sddm qt5-virtualkeyboard \
  hyprland hyprpolkitagent xdg-desktop-portal-hyprland gnome-keyring \
  fcitx5 fcitx5-gtk fcitx5-qt fcitx5-configtool
```

Then enable the display manager:

```bash
sudo systemctl enable sddm
```

## 4. Install `iio-hyprland` from the AUR

This setup uses `iio-hyprland` for automatic screen rotation.

Install it with your preferred AUR helper, for example:

```bash
yay -S iio-hyprland
```

## 5. Install the Fcitx virtual keyboard adapter

```bash
cd ~
git clone https://github.com/horriblename/fcitx-virtualkeyboard-adapter.git
cd fcitx-virtualkeyboard-adapter
mkdir -p build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr ..
cmake --build . -j"$(nproc)"
sudo cmake --install .
```

This is what lets Fcitx5 call the show and hide scripts for `wvkbd`.

## 6. Install DMS shell

Install DMS from its official source:

- https://danklinux.com/

## 7. Install Hyprgrass

First update Hyprland plugins:

```bash
hyprpm update
```

Then follow the Hyprgrass instructions:

- https://github.com/horriblename/hyprgrass

## 8. Clone both repos

The easiest option is to use the default location already used by the shipped config files and scripts:

```bash
mkdir -p ~/.local/src/hyprland-tablet
cd ~/.local/src/hyprland-tablet
git clone https://github.com/PickleHik3/hyprland-surface.git
git clone https://github.com/PickleHik3/qs-hyprview.git
```

If you use this location, you do not need to edit any paths before copying the files into `~/.config`.

If you choose a different location, you must update the absolute paths first.

The path to `qs-hyprview` is used in:

- `systemd-user/qs-hyprview.service`
- `hypr/hyprland.conf`

The path to `wvkbd-custom` is used in:

- `hypr/hyprland.conf`
- `fcitx5/conf/virtualkeyboardadapter.conf`
- every script under `wvkbd-custom/scripts/`

## 9. Copy the config files into place

Run these commands from this repo:

```bash
mkdir -p ~/.config/hypr
cp hypr/hyprland.conf ~/.config/hypr/hyprland.conf

mkdir -p ~/.config/environment.d
cp environment.d/10-fcitx.conf ~/.config/environment.d/10-fcitx.conf

mkdir -p ~/.config/fcitx5/conf
cp fcitx5/conf/virtualkeyboardadapter.conf ~/.config/fcitx5/conf/virtualkeyboardadapter.conf

mkdir -p ~/.config/systemd/user
cp systemd-user/qs-hyprview.service ~/.config/systemd/user/qs-hyprview.service

sudo install -d -m 0755 /usr/share/sddm/themes/silent/configs
sudo cp sddm/sddm.conf /etc/sddm.conf
sudo cp sddm/metadata.desktop /usr/share/sddm/themes/silent/metadata.desktop
sudo cp sddm/catppuccin-mocha-tablet.conf /usr/share/sddm/themes/silent/configs/catppuccin-mocha-tablet.conf
```

## 10. Reload everything

```bash
systemctl --user daemon-reload
systemctl --user enable --now qs-hyprview.service

systemctl --user import-environment QT_IM_MODULE XMODIFIERS
pkill -x fcitx5 || true
fcitx5 -dr
hyprctl reload
```

## 11. Check that it works

```bash
systemctl --user status qs-hyprview.service --no-pager
pgrep -af 'fcitx5|wvkbd-deskintl-custom|quickshell'
hyprctl binds | rg -n 'hyprgrass|expose|wvkbd'
```

You should see:

- `qs-hyprview.service` running
- `fcitx5` running
- `wvkbd-deskintl-custom` running
- Hyprgrass bindings loaded

## Touch gestures

These are the Hyprgrass gestures currently configured in `hypr/hyprland.conf`:

- bottom edge swipe up: open `qs-hyprview`
- left edge swipe down: close the active window
- right edge swipe down: open the DMS app drawer
- top edge swipe right: re-enable automatic keyboard behavior and show the keyboard now
- top edge swipe left: disable the keyboard
- two-finger long press: move the current window
- three-finger long press: resize the current floating window

## Notes

- The current `hyprland.conf` expects DMS config files under `~/.config/hypr/dms/`.
- Screen rotation is handled by `iio-hyprland`.
- The on-screen keyboard starts hidden, then shows and hides through the Fcitx5 adapter and the helper scripts in `wvkbd-custom/scripts/`.
