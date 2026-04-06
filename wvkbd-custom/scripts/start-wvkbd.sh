#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
BIN="$ROOT/bin/wvkbd-deskintl-custom"

if pgrep -f "$BIN" >/dev/null; then
  exit 0
fi

exec "$BIN" --hidden -H 280 -L 280 --fn "DejaVu Sans 20"
