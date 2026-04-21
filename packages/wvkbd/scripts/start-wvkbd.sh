#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
BIN="$ROOT/bin/wvkbd-deskintl-custom"
THEME_FILE="$ROOT/generated/noctalia-theme.sh"
STATE_DIR="/run/user/${UID}/wvkbd-custom"
VISIBLE_FLAG="${STATE_DIR}/visible"

WVKBD_ALPHA="242"
WVKBD_BG="171213"
WVKBD_FG="241e1f"
WVKBD_FG_SP="e3bdc5"
WVKBD_PRESS="ffb1c4"
WVKBD_PRESS_SP="e3bdc5"
WVKBD_SWIPE="edbd92"
WVKBD_SWIPE_SP="514346"
WVKBD_TEXT="ece0e1"
WVKBD_TEXT_SP="422930"

if [[ -f "$THEME_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$THEME_FILE"
fi

if pgrep -f "$BIN" >/dev/null; then
  exit 0
fi

mkdir -p "${STATE_DIR}"
rm -f "${VISIBLE_FLAG}"
if ! pgrep -f "${SCRIPT_DIR}/fcitx-wvkbd-auto.sh" >/dev/null; then
  nohup "${SCRIPT_DIR}/fcitx-wvkbd-auto.sh" >/dev/null 2>&1 &
fi

exec "$BIN" \
  --hidden \
  -H 280 \
  -L 280 \
  --fn "Noto Sans 18" \
  --alpha "$WVKBD_ALPHA" \
  --bg "$WVKBD_BG" \
  --fg "$WVKBD_FG" \
  --fg-sp "$WVKBD_FG_SP" \
  --press "$WVKBD_PRESS" \
  --press-sp "$WVKBD_PRESS_SP" \
  --swipe "$WVKBD_SWIPE" \
  --swipe-sp "$WVKBD_SWIPE_SP" \
  --text "$WVKBD_TEXT" \
  --text-sp "$WVKBD_TEXT_SP"
