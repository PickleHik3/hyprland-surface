#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

copy_tree() {
  local src="$1"
  local dest="$2"

  mkdir -p "$dest"
  rsync -a --delete "$src"/ "$dest"/
}

copy_tree_merge() {
  local src="$1"
  local dest="$2"

  mkdir -p "$dest"
  rsync -a "$src"/ "$dest"/
}

copy_file() {
  local src="$1"
  local dest="$2"

  mkdir -p "$(dirname "$dest")"
  cp -f "$src" "$dest"
}

copy_tree "$ROOT/packages/wvkbd" "$HOME/.config/hypr/apps/wvkbd"
copy_tree "$ROOT/packages/qs-hyprview" "$HOME/.config/hypr/apps/qs-hyprview"
copy_tree "$ROOT/packages/surface-dms" "$HOME/.config/DankMaterialShell/plugins/surface-dms"
copy_tree_merge "$ROOT/packages/hypr" "$HOME/.config/hypr"

copy_file "$ROOT/packages/wvkbd/integration/environment.d/10-fcitx.conf" "$HOME/.config/environment.d/10-fcitx.conf"
copy_file "$ROOT/packages/wvkbd/integration/fcitx5/conf/virtualkeyboardadapter.conf" "$HOME/.config/fcitx5/conf/virtualkeyboardadapter.conf"

copy_file "$ROOT/packages/qs-hyprview/systemd-user/qs-hyprview.service" "$HOME/.config/systemd/user/qs-hyprview.service"
copy_file "$ROOT/systemd/user/wvkbd.service" "$HOME/.config/systemd/user/wvkbd.service"
copy_file "$ROOT/systemd/user/fcitx-wvkbd-auto.service" "$HOME/.config/systemd/user/fcitx-wvkbd-auto.service"

"$HOME/.config/hypr/apps/wvkbd/build-custom.sh"

systemctl --user daemon-reload
systemctl --user enable --now qs-hyprview.service
systemctl --user enable --now wvkbd.service
systemctl --user enable --now fcitx-wvkbd-auto.service

if command -v dms >/dev/null 2>&1; then
  dms restart || true
fi

cat <<'EOF'
Installed hyprland-surface packages.

Next steps:
1. Restart the user session if this is the first Fcitx environment install.
2. In DMS settings, scan plugins and enable Surface Tablet Controls.
3. Add Recent Apps, Keyboard Toggle, and Back to DankBar.
EOF
