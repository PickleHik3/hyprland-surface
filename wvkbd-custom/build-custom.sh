#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$ROOT/src/wvkbd-v0.19.4"
OUT_DIR="$ROOT/bin"

mkdir -p "$OUT_DIR"
make -C "$SRC_DIR" LAYOUT=deskintl clean
make -C "$SRC_DIR" LAYOUT=deskintl wvkbd-deskintl
cp -f "$SRC_DIR/wvkbd-deskintl" "$OUT_DIR/wvkbd-deskintl-custom"
chmod +x "$OUT_DIR/wvkbd-deskintl-custom"
echo "Built: $OUT_DIR/wvkbd-deskintl-custom"
