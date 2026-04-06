# hyprland-surface

Live backup + setup guide for this Surface/Hyprland tablet workflow.

This repo stores only the active pieces used on the machine:
- Hyprland config (with custom gesture hooks and script paths)
- Fcitx5 env + virtual keyboard adapter config
- Custom `wvkbd` scripts/binary workspace
- `qs-hyprview` user service snapshot
- SDDM theme/config snapshots

Notes:
- DMS shell config files are intentionally **not** shipped here.
- `qs-hyprview` fork is expected as a sibling directory: `~/Documents/hyprland-tablet-backup/qs-hyprview`.

## 1. Base OS

Install EndeavourOS **without** a desktop environment:
- https://endeavouros.com/

Boot into TTY after install.

## 2. Linux Surface kernel

Install linux-surface kernel and components by following the official guide:
- https://github.com/linux-surface/linux-surface

Reboot into the linux-surface kernel when done.

## 3. Install SDDM + keyboard/display stack

```bash
sudo pacman -S --needed \
  sddm qt5-virtualkeyboard \
  hyprland hyprpolkitagent xdg-desktop-portal-hyprland gnome-keyring \
  fcitx5 fcitx5-gtk fcitx5-qt fcitx5-configtool \
  iio-sensor-proxy
```

Enable SDDM:

```bash
sudo systemctl enable sddm
```

## 4. Install Fcitx virtual keyboard adapter

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

## 5. Install DMS shell (official one-liner)

Run the official installer exactly from:
- https://danklinux.com/

Do not replace this with a copied command here; use the current one-liner from the website.

## 6. Install Hyprgrass

Use Hyprland plugin manager:

```bash
hyprpm add https://github.com/horriblename/hyprgrass
hyprpm enable hyprgrass
```

## 7. Clone backup + fork layout

Use this directory layout:

```text
~/Documents/hyprland-tablet-backup/
  hyprland-surface/   # this repo
  qs-hyprview/        # your fork repo
```

## 8. Copy configs from this repo

From `hyprland-surface` repo root:

```bash
# Hyprland
mkdir -p ~/.config/hypr
cp hypr/hyprland.conf ~/.config/hypr/hyprland.conf

# Fcitx environment
mkdir -p ~/.config/environment.d
cp environment.d/10-fcitx.conf ~/.config/environment.d/10-fcitx.conf

# Fcitx virtual keyboard adapter
mkdir -p ~/.config/fcitx5/conf
cp fcitx5/conf/virtualkeyboardadapter.conf ~/.config/fcitx5/conf/virtualkeyboardadapter.conf

# Quickshell overview service
mkdir -p ~/.config/systemd/user
cp systemd-user/qs-hyprview.service ~/.config/systemd/user/qs-hyprview.service

# SDDM (system-wide)
sudo install -d -m 0755 /usr/share/sddm/themes/silent/configs
sudo cp sddm/sddm.conf /etc/sddm.conf
sudo cp sddm/metadata.desktop /usr/share/sddm/themes/silent/metadata.desktop
sudo cp sddm/catppuccin-mocha-tablet.conf /usr/share/sddm/themes/silent/configs/catppuccin-mocha-tablet.conf
```

## 9. Apply + enable services

```bash
# User services
systemctl --user daemon-reload
systemctl --user enable --now qs-hyprview.service

# Ensure env vars are imported in current session too
systemctl --user import-environment QT_IM_MODULE XMODIFIERS

# Start IM + keyboard once now
pkill -x fcitx5 || true
fcitx5 -dr
~/Documents/hyprland-tablet-backup/hyprland-surface/wvkbd-custom/scripts/start-wvkbd.sh

# Reload Hyprland after config copy
hyprctl reload
```

## 10. Verify

```bash
systemctl --user status qs-hyprview.service --no-pager
pgrep -af 'fcitx5|wvkbd-deskintl-custom|quickshell'
hyprctl binds | rg -n 'hyprgrass|expose|wvkbd'
```

Expected:
- `qs-hyprview.service` running from `~/Documents/hyprland-tablet-backup/qs-hyprview`
- `fcitx5` running
- `wvkbd-deskintl-custom` running (hidden)
- Hyprgrass edge gestures loaded

## 11. Update workflow

- Edit files in this repo.
- Copy changed files to live paths.
- Reload Hyprland / restart user services as needed.
- Keep `qs-hyprview` fork updated separately in its own repo.
