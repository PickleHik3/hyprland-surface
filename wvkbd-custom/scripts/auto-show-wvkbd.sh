#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="/run/user/${UID}/wvkbd-custom"
DISABLED_FLAG="${STATE_DIR}/disabled"

mkdir -p "${STATE_DIR}"
rm -f "${DISABLED_FLAG}"

# Re-enable automatic behavior and force-show now.
/home/amalv/Documents/hyprland-tablet-backup/hyprland-surface/wvkbd-custom/scripts/show-wvkbd.sh
