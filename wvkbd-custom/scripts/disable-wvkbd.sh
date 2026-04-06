#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="/run/user/${UID}/wvkbd-custom"
DISABLED_FLAG="${STATE_DIR}/disabled"

mkdir -p "${STATE_DIR}"
touch "${DISABLED_FLAG}"

# Hide immediately and keep it disabled for auto-popup calls.
/home/amalv/Documents/hyprland-tablet-backup/hyprland-surface/wvkbd-custom/scripts/hide-wvkbd.sh
