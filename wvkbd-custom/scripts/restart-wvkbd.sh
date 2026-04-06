#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
BIN="$ROOT/bin/wvkbd-deskintl-custom"

pkill -f "$BIN" || true
exec "$ROOT/scripts/start-wvkbd.sh"
