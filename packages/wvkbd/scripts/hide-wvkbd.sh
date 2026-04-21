#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
BIN="${ROOT}/bin/wvkbd-deskintl-custom"
STATE_DIR="/run/user/${UID}/wvkbd-custom"
VISIBLE_FLAG="${STATE_DIR}/visible"

mkdir -p "${STATE_DIR}"
rm -f "${VISIBLE_FLAG}"
pkill -SIGUSR1 -f "$BIN" || true
