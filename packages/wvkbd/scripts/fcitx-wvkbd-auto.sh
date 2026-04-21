#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="/run/user/${UID}/wvkbd-custom"
DISABLED_FLAG="${STATE_DIR}/disabled"
LOCK_FILE="${STATE_DIR}/fcitx-auto.lock"
SEEN_FOCUS_FLAG="${STATE_DIR}/seen-focus"

mkdir -p "${STATE_DIR}"
exec 9>"${LOCK_FILE}"
flock -n 9 || exit 0

has_fcitx_focus() {
  busctl --user call org.fcitx.Fcitx5 /controller org.fcitx.Fcitx.Controller1 DebugInfo 2>/dev/null | grep -q 'focus:1'
}

while true; do
  if [[ -f "${DISABLED_FLAG}" ]]; then
    rm -f "${SEEN_FOCUS_FLAG}"
    "${SCRIPT_DIR}/hide-wvkbd.sh" >/dev/null 2>&1 || true
    sleep 0.4
    continue
  fi

  if has_fcitx_focus; then
    touch "${SEEN_FOCUS_FLAG}"
    "${SCRIPT_DIR}/show-wvkbd.sh" >/dev/null 2>&1 || true
  elif [[ -f "${SEEN_FOCUS_FLAG}" ]]; then
    rm -f "${SEEN_FOCUS_FLAG}"
    "${SCRIPT_DIR}/hide-wvkbd.sh" >/dev/null 2>&1 || true
  fi

  sleep 0.25
done
