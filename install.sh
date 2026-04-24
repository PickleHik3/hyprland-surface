#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

printf '%s\n' \
  'Choose what to install:' \
  '1. All' \
  '2. wvkbd' \
  '3. qs-hyprview (window overview)' \
  '4. DMS plugin'
printf 'Enter choice [1-4]: '
read -r choice

case "$choice" in
  1)
    "$ROOT/scripts/install-hypr-config.sh"
    "$ROOT/scripts/install-qs-hyprview.sh"
    "$ROOT/scripts/install-wvkbd.sh"
    "$ROOT/scripts/install-surface-dms.sh"
    cat <<'EOF'
Installed the full hyprland-surface package set.

Installed locations:
- Hyprland config: ~/.config/hypr
- wvkbd app: ~/.config/hypr/apps/wvkbd
- wvkbd binary: ~/.config/hypr/apps/wvkbd/bin/wvkbd-deskintl-custom
- qs-hyprview app: ~/.config/hypr/apps/qs-hyprview
- DMS plugin: ~/.config/DankMaterialShell/plugins/surface-dms
- Fcitx environment file: ~/.config/environment.d/10-fcitx.conf
- Fcitx virtual keyboard config: ~/.config/fcitx5/conf/virtualkeyboardadapter.conf
- user services: ~/.config/systemd/user/{wvkbd.service,fcitx-wvkbd-auto.service,qs-hyprview.service}

For direct component installs, use:
- ./scripts/install-hypr-config.sh
- ./scripts/install-qs-hyprview.sh
- ./scripts/install-wvkbd.sh
- ./scripts/install-surface-dms.sh

Next steps:
1. Restart the user session if this is the first Fcitx environment install.
2. In DMS settings, scan plugins and enable Surface Tablet Controls.
3. Add Recent Apps, Keyboard Toggle, and Back to DankBar.
EOF
    ;;
  2)
    "$ROOT/scripts/install-wvkbd.sh"
    ;;
  3)
    "$ROOT/scripts/install-qs-hyprview.sh"
    ;;
  4)
    "$ROOT/scripts/install-surface-dms.sh"
    ;;
  *)
    printf 'Invalid choice: %s\n' "$choice" >&2
    exit 1
    ;;
esac
