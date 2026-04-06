#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="/run/user/${UID}/wvkbd-custom"
DISABLED_FLAG="${STATE_DIR}/disabled"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "${STATE_DIR}"
touch "${DISABLED_FLAG}"

# Hide immediately and keep it disabled for auto-popup calls.
"${SCRIPT_DIR}/hide-wvkbd.sh"
