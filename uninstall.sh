#!/usr/bin/env bash
set -euo pipefail

systemctl --user disable --now fcitx-wvkbd-auto.service 2>/dev/null || true
systemctl --user disable --now wvkbd.service 2>/dev/null || true
systemctl --user disable --now qs-hyprview.service 2>/dev/null || true

rm -f "$HOME/.config/systemd/user/fcitx-wvkbd-auto.service"
rm -f "$HOME/.config/systemd/user/wvkbd.service"
rm -f "$HOME/.config/systemd/user/qs-hyprview.service"

rm -rf "$HOME/.config/hypr/apps/wvkbd"
rm -rf "$HOME/.config/hypr/apps/qs-hyprview"
rm -rf "$HOME/.config/DankMaterialShell/plugins/surface-dms"

systemctl --user daemon-reload

cat <<'EOF'
Removed hyprland-surface app packages and user services.

Hyprland, Fcitx, DMS settings, SDDM files, and copied environment files were left in place.
EOF
