# hyprland-surface

Guide repo for rebuilding the Surface Pro 7 Hyprland setup from the split
repositories.

This repo is the guide and glue layer. The app code lives elsewhere.

## Repos

Clone these repos into their default live paths:

- `wvkbd`: `https://github.com/PickleHik3/wvkbd`
- `qs-hyprview`: `https://github.com/PickleHik3/qs-hyprview`
- `surface-dms`: `https://github.com/PickleHik3/surface-dms`

Default live paths:

- `wvkbd`: `~/.config/hypr/apps/wvkbd`
- `qs-hyprview`: `~/.config/hypr/apps/qs-hyprview`
- `surface-dms`: `~/.config/DankMaterialShell/plugins/surface-dms`

This repo only keeps the guide and the optional `sddm/` files.

## What you get

- Hyprland on a Surface device
- Dank Material Shell
- `qs-hyprview` recent apps / overview
- custom `wvkbd`
- optional DMS bar widgets for recent apps, keyboard toggle, and back
- `fcitx5` virtual keyboard adapter
- `iio-hyprland`

## 1. Base system

1. Install an Arch-based system.
2. Install the `linux-surface` kernel:
   `https://github.com/linux-surface/linux-surface`
3. Reboot into the Surface kernel.

## 2. Packages

```bash
sudo pacman -S --needed \
  sddm qt5-virtualkeyboard \
  hyprland hyprpolkitagent xdg-desktop-portal-hyprland gnome-keyring \
  fcitx5 fcitx5-gtk fcitx5-qt fcitx5-configtool \
  quickshell jq git
```

Also install:

- `dms-shell`
- `iio-hyprland` from the AUR
- `hyprgrass` using its upstream instructions

Install Dank Material Shell using the official docs:

- `https://danklinux.com/docs/dankmaterialshell/installation/`
- `https://danklinux.com/docs/dankmaterialshell/compositors/`

Install the Fcitx virtual keyboard adapter:

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

## 3. Clone the repos

```bash
mkdir -p ~/.config/hypr/apps
git clone https://github.com/PickleHik3/wvkbd.git ~/.config/hypr/apps/wvkbd
git clone https://github.com/PickleHik3/qs-hyprview.git ~/.config/hypr/apps/qs-hyprview

mkdir -p ~/.config/DankMaterialShell/plugins
git clone https://github.com/PickleHik3/surface-dms.git ~/.config/DankMaterialShell/plugins/surface-dms
```

Build `wvkbd`:

```bash
cd ~/.config/hypr/apps/wvkbd
./build-custom.sh
```

## 4. Install the integration files from each repo

```bash
mkdir -p ~/.config/environment.d
cp ~/.config/hypr/apps/wvkbd/integration/environment.d/10-fcitx.conf ~/.config/environment.d/10-fcitx.conf

mkdir -p ~/.config/fcitx5/conf
cp ~/.config/hypr/apps/wvkbd/integration/fcitx5/conf/virtualkeyboardadapter.conf ~/.config/fcitx5/conf/virtualkeyboardadapter.conf

mkdir -p ~/.config/systemd/user
cp ~/.config/hypr/apps/qs-hyprview/systemd-user/qs-hyprview.service ~/.config/systemd/user/qs-hyprview.service

sudo install -d -m 0755 /usr/share/sddm/themes/silent/configs
sudo cp sddm/sddm.conf /etc/sddm.conf
sudo cp sddm/metadata.desktop /usr/share/sddm/themes/silent/metadata.desktop
sudo cp sddm/catppuccin-mocha-tablet.conf /usr/share/sddm/themes/silent/configs/catppuccin-mocha-tablet.conf
```

Enable the user service:

```bash
systemctl --user daemon-reload
systemctl --user enable --now qs-hyprview.service
```

## 5. Add the Hyprland lines you need

Do not copy a full `hyprland.conf` from here. Add these pieces to your own
config.

Startup:

```ini
exec-once = dms run
exec-once = systemctl --user start hyprland-session.target
exec-once = uwsm-app -- ~/.config/hypr/apps/wvkbd/scripts/start-wvkbd.sh
exec-once = uwsm-app -- iio-hyprland
```

Hyprgrass:

```ini
plugin {
    touch_gestures {
        workspace_swipe_fingers = 3
        workspace_swipe_edge = d
        edge_margin = 10

        hyprgrass-bind = , edge:d:u, exec, quickshell ipc -p $HOME/.config/hypr/apps/qs-hyprview call expose open smartgrid
        hyprgrass-bind = , edge:l:d, killactive
        hyprgrass-bind = , edge:u:r, exec, $HOME/.config/hypr/apps/wvkbd/scripts/auto-show-wvkbd.sh
        hyprgrass-bind = , edge:u:l, exec, $HOME/.config/hypr/apps/wvkbd/scripts/disable-wvkbd.sh
        hyprgrass-bindm = , longpress:2, movewindow
        hyprgrass-bindm = , longpress:3, resizewindow
    }
}
```

## 6. Enable the DMS plugin

1. Open DMS Settings.
2. Go to `Plugins`.
3. Click `Scan for Plugins`.
4. Enable `Surface Tablet Controls`.
5. Open the plugin settings page.
6. Click `Create Missing Default Variants`.
7. Go to DankBar settings and add the items you want:
   - `Recent Apps`
   - `Keyboard Toggle`
   - `Back`
8. Restart the shell with `dms restart`.

The plugin can also still be added as one grouped widget if you want the old
combined layout.

Official DMS plugin docs:

- `https://danklinux.com/docs/dankmaterialshell/plugins-overview/`
- `https://danklinux.com/docs/dankmaterialshell/plugin-development/`

## 7. Optional DMS-themed `wvkbd`

The `wvkbd` repo ships a generated theme hook for shell-driven colors. If you
do not use that flow, the keyboard still works with the defaults in
`start-wvkbd.sh`.

## 8. Verify

```bash
systemctl --user status qs-hyprview.service --no-pager
pgrep -af 'fcitx5|wvkbd-deskintl-custom|quickshell|dms'
hyprctl binds | rg -n 'hyprgrass|qs-hyprview|wvkbd'
dms ipc call plugins list
```

Expected result:

- `qs-hyprview.service` is running
- `fcitx5` is running
- `wvkbd-deskintl-custom` is running
- DMS is running
- `surfaceTabletControls` is listed as loaded
- the Hyprgrass bindings are present
