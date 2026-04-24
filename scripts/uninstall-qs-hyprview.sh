#!/usr/bin/env bash
set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

disable_user_service qs-hyprview.service

remove_file "$HOME/.config/systemd/user/qs-hyprview.service"
remove_tree "$HOME/.config/hypr/apps/qs-hyprview"

reload_user_systemd

cat <<'EOF'
Removed qs-hyprview and its user service.
EOF
