#!/usr/bin/env bash
set -euo pipefail

BIN="/home/amalv/Documents/hyprland-tablet-backup/hyprland-surface/wvkbd-custom/bin/wvkbd-deskintl-custom"
pkill -SIGUSR1 -f "$BIN" || true
