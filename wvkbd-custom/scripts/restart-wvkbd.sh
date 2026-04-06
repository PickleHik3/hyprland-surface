#!/usr/bin/env bash
set -euo pipefail

ROOT="/home/amalv/Documents/hyprland-tablet-backup/hyprland-surface/wvkbd-custom"
BIN="$ROOT/bin/wvkbd-deskintl-custom"

pkill -f "$BIN" || true
exec "$ROOT/scripts/start-wvkbd.sh"
