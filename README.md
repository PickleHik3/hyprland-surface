# hyprland-surface

Guide repo for rebuilding my Surface Pro 7 Hyprland setup around Dank Material
Shell.

This repo is the glue layer. The code lives in separate repos:

- `wvkbd`: `https://github.com/PickleHik3/wvkbd`
- `qs-hyprview`: `https://github.com/PickleHik3/qs-hyprview`
- `surface-dms`: `https://github.com/PickleHik3/surface-dms`

It also keeps:

- SDDM files in `sddm/`
- a live Hyprland config snapshot in `backup/hypr/`
- optional input integration snapshots in `backup/environment.d/` and `backup/fcitx5/`

## Intended install flow

This is the reinstall flow this repo is written for:

1. Install Arch Linux.
2. Install `sddm` and `sddm-silent-theme`.
3. Install Dank Material Shell using the official DMS install method.
4. Clone `wvkbd`, `qs-hyprview`, and `surface-dms` into the default paths.
5. Build the custom `wvkbd` layout.
6. Copy the SDDM and Hyprland config files you want from this repo.
7. In DMS settings, scan for plugins and enable `Surface Tablet Controls`.

That plan is good.

One correction:

- `surface-dms` is not installed from the DMS plugin registry.
- Clone it to `~/.config/DankMaterialShell/plugins/surface-dms`.
- Then use the DMS GUI to scan and enable it.

## Extra packages

Do not list Hyprland, portals, or DMS-managed packages here. The official DMS
install flow should handle the shell side.

Install these extra packages for this setup:

```bash
sudo pacman -S --needed \
  sddm qt5-virtualkeyboard \
  fcitx5 fcitx5-gtk fcitx5-qt fcitx5-configtool \
  jq git cmake base-devel
```

Install these separately:

- `sddm-silent-theme`
- `iio-hyprland`
- `hyprgrass`

If this is a Surface device, also install the `linux-surface` kernel using its
official project instructions.

## Default paths

Clone the repos into these paths so the defaults work without editing:

- `~/.config/hypr/apps/wvkbd`
- `~/.config/hypr/apps/qs-hyprview`
- `~/.config/DankMaterialShell/plugins/surface-dms`

If you use these exact paths:

- the `surface-dms` recent-apps action already points to `qs-hyprview`
- the default keyboard script paths already point to `wvkbd`
- the Hyprland gesture examples below already match your install

## 1. Clone the repos

```bash
mkdir -p ~/.config/hypr/apps
git clone https://github.com/PickleHik3/wvkbd.git ~/.config/hypr/apps/wvkbd
git clone https://github.com/PickleHik3/qs-hyprview.git ~/.config/hypr/apps/qs-hyprview

mkdir -p ~/.config/DankMaterialShell/plugins
git clone https://github.com/PickleHik3/surface-dms.git ~/.config/DankMaterialShell/plugins/surface-dms
```

## 2. Build `wvkbd`

```bash
cd ~/.config/hypr/apps/wvkbd
./build-custom.sh
```

## 3. Install `qs-hyprview`

```bash
mkdir -p ~/.config/systemd/user
cp ~/.config/hypr/apps/qs-hyprview/systemd-user/qs-hyprview.service ~/.config/systemd/user/qs-hyprview.service

systemctl --user daemon-reload
systemctl --user enable --now qs-hyprview.service
```

## 4. Optional `fcitx5` integration

This is only needed if you want `fcitx5` to drive keyboard show/hide
automatically while typing.

If you only want the custom `wvkbd` binary and the helper scripts for manual use
from Hyprland gestures or the DMS plugin, you can skip this section.

```bash
mkdir -p ~/.config/environment.d
cp ~/.config/hypr/apps/wvkbd/integration/environment.d/10-fcitx.conf ~/.config/environment.d/10-fcitx.conf

mkdir -p ~/.config/fcitx5/conf
cp ~/.config/hypr/apps/wvkbd/integration/fcitx5/conf/virtualkeyboardadapter.conf ~/.config/fcitx5/conf/virtualkeyboardadapter.conf
```

What these files do:

- `10-fcitx.conf` sets the IM environment variables
- `virtualkeyboardadapter.conf` points Fcitx to the `wvkbd` show/hide scripts

## 5. Install the SDDM files from this repo

This repo already contains the SDDM files I use for the silent theme:

- `sddm/sddm.conf`
- `sddm/metadata.desktop`
- `sddm/catppuccin-mocha-tablet.conf`

Install them like this:

```bash
sudo cp sddm/sddm.conf /etc/sddm.conf
sudo install -d -m 0755 /usr/share/sddm/themes/silent/configs
sudo cp sddm/metadata.desktop /usr/share/sddm/themes/silent/metadata.desktop
sudo cp sddm/catppuccin-mocha-tablet.conf /usr/share/sddm/themes/silent/configs/catppuccin-mocha-tablet.conf
```

What this does:

- enables the `silent` SDDM theme
- enables `qtvirtualkeyboard` in SDDM
- points the theme metadata at the tablet-tuned config file

## 6. Restore the Hyprland config you want

This repo contains a snapshot of the current live Hyprland config in:

- `backup/hypr/`

It does not include the app repos under `~/.config/hypr/apps/`.

To restore the snapshot directly:

```bash
mkdir -p ~/.config/hypr
cp -r backup/hypr/* ~/.config/hypr/
```

Important notes:

- this snapshot keeps the current split-config layout
- it starts `dms run`
- it starts `fcitx5`
- it starts the custom `wvkbd`
- it starts `iio-hyprland`
- it includes the `qs-hyprview` Hyprgrass gesture

The current live startup snapshot includes:

- `exec-once = dms run`
- `exec-once = uwsm-app -- fcitx5 --disable=notificationitem --disable=notifications`
- `exec-once = uwsm-app -- /home/amalv/.config/hypr/apps/wvkbd/scripts/start-wvkbd.sh`
- `exec-once = uwsm-app -- iio-hyprland`

The current live gesture snapshot includes:

- down edge up: open `qs-hyprview`
- up edge right: enable auto keyboard
- up edge left: disable keyboard auto mode

## 7. Enable the DMS plugin

1. Open DMS settings.
2. Go to `Plugins`.
3. Click `Scan for Plugins`.
4. Enable `Surface Tablet Controls`.
5. Open its settings page.
6. Click `Create Missing Default Variants`.
7. Add the variants you want in DankBar settings.

Recommended variants:

- `Recent Apps`
- `Keyboard Toggle`
- `Back`
- `Home`

If you cloned `qs-hyprview` into the default path, the recent-apps button should
work without changing plugin settings.

If you installed `qs-hyprview` somewhere else, change the `qs-hyprview path` in
the plugin settings page.

## 8. Verify

```bash
systemctl --user status qs-hyprview.service --no-pager
pgrep -af 'fcitx5|wvkbd-deskintl-custom|quickshell|dms'
hyprctl binds | rg -n 'hyprgrass|qs-hyprview|wvkbd'
dms ipc plugins status surfaceTabletControls
```

Expected result:

- `qs-hyprview.service` is running
- `fcitx5` is running if you enabled it
- `wvkbd-deskintl-custom` is running
- DMS is running
- `surfaceTabletControls` is loaded
- the Hyprgrass bindings are present
