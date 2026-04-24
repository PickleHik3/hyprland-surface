#!/usr/bin/env bash
set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

disable_user_service fcitx-wvkbd-auto.service
disable_user_service wvkbd.service

remove_file "$HOME/.config/systemd/user/fcitx-wvkbd-auto.service"
remove_file "$HOME/.config/systemd/user/wvkbd.service"
remove_tree "$HOME/.config/hypr/apps/wvkbd"

reload_user_systemd

cat <<'EOF'
Removed wvkbd package and its user services.

Fcitx environment files and copied user configuration were left in place.
EOF
