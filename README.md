# hyprland-surface

Guide repo for rebuilding the Surface Pro 7 Hyprland setup from the split repositories.

This repo is the guide and glue layer. The app code lives elsewhere.

## Repos

Clone these into `~/.config/hypr/apps`:

- `wvkbd`: `https://github.com/PickleHik3/wvkbd`
- `qs-hyprview`: `https://github.com/PickleHik3/qs-hyprview`
- `surface-noctalia`: `https://github.com/PickleHik3/surface-noctalia`

This repo only keeps the extra config files that do not belong in those repos:

- `environment.d/10-fcitx.conf`
- `fcitx5/conf/virtualkeyboardadapter.conf`
- `systemd-user/qs-hyprview.service`
- `sddm/`

## What you get

- Hyprland on a Surface device
- Noctalia Shell
- `qs-hyprview` recent apps / overview
- custom `wvkbd`
- optional Noctalia bar plugin for keyboard and recent apps
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
  quickshell git
```

Also install:

- `iio-hyprland` from the AUR
- `hyprgrass` using its upstream instructions
- Noctalia Shell using the official install docs:
  `https://docs.noctalia.dev/getting-started/installation/`

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
cd ~/.config/hypr/apps

git clone https://github.com/PickleHik3/wvkbd.git
git clone https://github.com/PickleHik3/qs-hyprview.git
git clone https://github.com/PickleHik3/surface-noctalia.git
```

Build `wvkbd`:

```bash
cd ~/.config/hypr/apps/wvkbd
./build-custom.sh
```

## 4. Copy the config files from this repo

Run these commands from this repo:

```bash
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

Enable the user service:

```bash
systemctl --user daemon-reload
systemctl --user enable --now qs-hyprview.service
```

## 5. Add the Hyprland lines you need

Do not copy a full `hyprland.conf` from here. Add these pieces to your own config.

Startup:

```ini
exec-once = qs -c noctalia-shell --no-duplicate
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

## 6. Install the Noctalia plugin

Noctalia already supports custom plugin repositories through its GUI.

In the Plugins section, add this repository:

- `https://github.com/PickleHik3/surface-noctalia`

Then install:

- `Surface Tablet Controls`

That plugin gives you:

- a recent-apps button for `qs-hyprview`
- keyboard actions for `wvkbd`: auto, show, hide, disable

Official Noctalia plugin docs:

- `https://docs.noctalia.dev/plugins/overview/`
- `https://docs.noctalia.dev/development/plugins/getting-started/`

## 7. Optional: Noctalia theming for `wvkbd`

Enable Noctalia user templates, then use the `wvkbd` template shipped in the `wvkbd` repo.

The live path layout is:

- `~/.config/noctalia/user-templates.toml`
- `~/.config/noctalia/templates/wvkbd-theme.sh`
- `~/.config/hypr/apps/wvkbd/generated/noctalia-theme.sh`

## 8. Verify

```bash
systemctl --user status qs-hyprview.service --no-pager
pgrep -af 'fcitx5|wvkbd-deskintl-custom|quickshell'
hyprctl binds | rg -n 'hyprgrass|qs-hyprview|wvkbd'
```

Expected result:

- `qs-hyprview.service` is running
- `fcitx5` is running
- `wvkbd-deskintl-custom` is running
- the Hyprgrass bindings are present
