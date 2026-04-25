#!/usr/bin/env bash
set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

disable_user_service qs-hyprview.service

remove_file "$HOME/.config/systemd/user/qs-hyprview.service"
remove_tree "$HOME/.config/hypr/apps/qs-hyprview"
remove_matugen_template "hyprland_surface_qs_hyprview"

reload_user_systemd

cat <<'EOF'
Removed qs-hyprview, its user service, and its matugen template registration.
EOF
