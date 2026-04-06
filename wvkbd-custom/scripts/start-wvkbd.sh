#!/usr/bin/env bash
set -euo pipefail

ROOT="/home/amalv/Documents/hyprland-tablet-backup/hyprland-surface/wvkbd-custom"
BIN="$ROOT/bin/wvkbd-deskintl-custom"

if pgrep -f "$BIN" >/dev/null; then
  exit 0
fi

exec "$BIN" --hidden -H 280 -L 280 --fn "DejaVu Sans 20"
