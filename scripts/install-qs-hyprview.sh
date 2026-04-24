#!/usr/bin/env bash
set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

copy_tree "$ROOT/packages/qs-hyprview" "$HOME/.config/hypr/apps/qs-hyprview"
copy_file "$ROOT/packages/qs-hyprview/systemd-user/qs-hyprview.service" "$HOME/.config/systemd/user/qs-hyprview.service"

reload_user_systemd
enable_user_service qs-hyprview.service

cat <<'EOF'
Installed qs-hyprview and enabled its user service.

Installed locations:
- app files: ~/.config/hypr/apps/qs-hyprview
- entry QML: ~/.config/hypr/apps/qs-hyprview/shell.qml
- user service: ~/.config/systemd/user/qs-hyprview.service

Verify:
- systemctl --user status qs-hyprview.service --no-pager
- quickshell ipc -p "$HOME/.config/hypr/apps/qs-hyprview" call expose open smartgrid
EOF
