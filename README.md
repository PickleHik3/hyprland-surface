# hyprland-surface

Live backup + reproducible setup notes for this Surface tablet Hyprland workflow.

This repo intentionally contains only active, local customizations:
- `hypr/hyprland.conf`
- `environment.d/10-fcitx.conf`
- `fcitx5/conf/virtualkeyboardadapter.conf`
- `wvkbd-custom/`
- `systemd-user/qs-hyprview.service`
- `sddm/` snapshots

DMS shell configs are intentionally not included.

## 1. Install base OS (no DE)

Install EndeavourOS without a desktop environment:
- https://endeavouros.com/

Reboot and log in to TTY.

## 2. Install linux-surface kernel

Follow the official instructions exactly:
- https://github.com/linux-surface/linux-surface

Reboot into linux-surface kernel.

## 3. Install core packages

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

## 5. Install DMS shell

Use the official installer from:
- https://danklinux.com/

## 6. Hyprgrass prerequisite + official setup

Before installing/configuring Hyprgrass, update Hyprland plugins:

```bash
hyprpm update
```

Then follow the official Hyprgrass repo instructions:
- https://github.com/horriblename/hyprgrass

## 7. Clone repos (any location)

You can clone these repos anywhere.

- `hyprland-surface` (this repo)
- `qs-hyprview` (your fork)

Only one path is critical at runtime: the local path to `qs-hyprview` used by:
- `systemd-user/qs-hyprview.service` (`ExecStart`)
- `hypr/hyprland.conf` gesture IPC command (`quickshell ipc -p ...`)

If you use non-default paths, update these files before copying to live config.

## 8. Copy config files

From this repo root:

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

## 9. Apply and reload

```bash
systemctl --user daemon-reload
systemctl --user enable --now qs-hyprview.service

systemctl --user import-environment QT_IM_MODULE XMODIFIERS
pkill -x fcitx5 || true
fcitx5 -dr
hyprctl reload
```

## 10. Verify

```bash
systemctl --user status qs-hyprview.service --no-pager
pgrep -af 'fcitx5|wvkbd-deskintl-custom|quickshell'
hyprctl binds | rg -n 'hyprgrass|expose|wvkbd'
```

Expected:
- `qs-hyprview.service` active
- `fcitx5` active
- `wvkbd-deskintl-custom` active
- Hyprgrass binds loaded
