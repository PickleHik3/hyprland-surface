#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="/run/user/${UID}/wvkbd-custom"
DISABLED_FLAG="${STATE_DIR}/disabled"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "${STATE_DIR}"
rm -f "${DISABLED_FLAG}"

# Re-enable automatic behavior and force-show now.
"${SCRIPT_DIR}/show-wvkbd.sh"
