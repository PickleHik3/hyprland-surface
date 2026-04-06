#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
BIN="${ROOT}/bin/wvkbd-deskintl-custom"
STATE_DIR="/run/user/${UID}/wvkbd-custom"
DISABLED_FLAG="${STATE_DIR}/disabled"

# When disabled mode is active, block both manual and automatic show requests.
if [[ -f "${DISABLED_FLAG}" ]]; then
  exit 0
fi

pkill -SIGUSR2 -f "$BIN" || true
