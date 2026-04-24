# Repository Guidelines

## Project Structure & Module Organization

This repository packages a Surface Hyprland tablet setup. Top-level
entry points are `install.sh` and `uninstall.sh`. Packaged components live under
`packages/`: `hypr/` contains Hyprland configuration, `wvkbd/` contains the
patched C keyboard source plus helper scripts, `qs-hyprview/` contains the
Quickshell overview QML app, `surface-dms/` contains the Dank Material Shell
plugin, and `sddm/` contains optional system theme files. User services are in
`systemd/user/`; operational notes are in `docs/`.

## Build, Test, and Development Commands

- `./install.sh`: copies packages into the live `~/.config` paths, builds the
  custom `wvkbd` binary, reloads user systemd units, and restarts DMS when
  available.
- `./uninstall.sh`: removes packaged app copies and user services while leaving
  user configuration in place.
- `packages/wvkbd/build-custom.sh`: builds `bin/wvkbd-deskintl-custom`.
- `make -C packages/wvkbd LAYOUT=deskintl wvkbd-deskintl`: compile the keyboard
  directly for development.
- `make -C packages/wvkbd LAYOUT=deskintl clean`: remove generated keyboard
  build output.
- `systemctl --user status qs-hyprview.service --no-pager`: verify the overview
  service after installation.

## Coding Style & Naming Conventions

Shell scripts use Bash with `set -euo pipefail`, quoted variables, and helper
functions for repeated file operations. QML files use PascalCase
component filenames such as `WindowThumbnail.qml`; keep module files grouped
under their existing `modules/` or `layouts/` directories. C sources in
`packages/wvkbd/` follow the existing upstream style and can be formatted with
`make -C packages/wvkbd format` when `clang-format` is available. Keep config
filenames ordered and descriptive, for example `packages/hypr/conf/50-binds.conf`.

## Testing Guidelines

There is no standalone automated test suite. Validate changes with targeted
builds and runtime checks. For keyboard changes, run `packages/wvkbd/build-custom.sh`.
For installer or service changes, run `./install.sh` on a suitable Hyprland user
session, then check the relevant `systemctl --user status ... --no-pager`
commands and `pgrep -af 'fcitx5|wvkbd|quickshell|dms'`. For QML changes, verify
the Quickshell IPC commands documented in `packages/qs-hyprview/README.md`.

## Commit & Pull Request Guidelines

Git history uses concise imperative commits, for example `Clarify README install
requirements` and `Clean packaged Hypr startup paths`. Keep commits focused on
one component or behavior. Pull requests should describe the affected package,
list commands or manual checks performed, mention any required session restart,
and include screenshots or short recordings for visible QML, DMS, SDDM, or
Hyprland UI changes.

## Security & Configuration Tips

Treat `install.sh` as a live user-configuration deployer: it uses `rsync
--delete` for several app directories under `~/.config`. Do not add writes to
system paths without making them explicit and documented; SDDM files are
intentionally installed manually with `sudo`.
