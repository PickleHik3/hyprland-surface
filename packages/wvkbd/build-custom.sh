#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="$ROOT/bin"

mkdir -p "$OUT_DIR"
make -C "$ROOT" LAYOUT=deskintl clean
make -C "$ROOT" LAYOUT=deskintl wvkbd-deskintl
cp -f "$ROOT/wvkbd-deskintl" "$OUT_DIR/wvkbd-deskintl-custom"
chmod +x "$OUT_DIR/wvkbd-deskintl-custom"
echo "Built: $OUT_DIR/wvkbd-deskintl-custom"
