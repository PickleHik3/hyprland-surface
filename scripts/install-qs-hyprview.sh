#!/usr/bin/env bash
set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

copy_tree "$ROOT/packages/qs-hyprview" "$HOME/.config/hypr/apps/qs-hyprview"
copy_file "$ROOT/packages/qs-hyprview/systemd-user/qs-hyprview.service" "$HOME/.config/systemd/user/qs-hyprview.service"
upsert_matugen_template \
  "hyprland_surface_qs_hyprview" \
  "$ROOT/packages/qs-hyprview/matugen/qs-hyprview-theme.json" \
  "$HOME/.config/hypr/apps/qs-hyprview/theme.json"

reload_user_systemd
enable_user_service qs-hyprview.service
restart_user_service qs-hyprview.service
restart_dms_if_present

cat <<'EOF'
Installed qs-hyprview and enabled its user service.

Installed locations:
- app files: ~/.config/hypr/apps/qs-hyprview
- entry QML: ~/.config/hypr/apps/qs-hyprview/shell.qml
- generated palette target: ~/.config/hypr/apps/qs-hyprview/theme.json
- user service: ~/.config/systemd/user/qs-hyprview.service
- matugen template: ~/.config/matugen/templates/hyprland_surface_qs_hyprview.json
- matugen config: ~/.config/matugen/config.toml

Verify:
- systemctl --user status qs-hyprview.service --no-pager
- quickshell ipc -p "$HOME/.config/hypr/apps/qs-hyprview" call expose open smartgrid
EOF
