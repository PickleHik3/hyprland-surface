#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"

copy_tree() {
  local src="$1"
  local dest="$2"

  mkdir -p "$dest"
  rsync -a --delete "$src"/ "$dest"/
}

copy_tree_merge() {
  local src="$1"
  local dest="$2"

  mkdir -p "$dest"
  rsync -a "$src"/ "$dest"/
}

copy_file() {
  local src="$1"
  local dest="$2"

  mkdir -p "$(dirname "$dest")"
  cp -f "$src" "$dest"
}

remove_file() {
  local path="$1"
  rm -f "$path"
}

remove_tree() {
  local path="$1"
  rm -rf "$path"
}

reload_user_systemd() {
  systemctl --user daemon-reload
}

enable_user_service() {
  local service="$1"
  systemctl --user enable --now "$service"
}

disable_user_service() {
  local service="$1"
  systemctl --user disable --now "$service" 2>/dev/null || true
}

restart_dms_if_present() {
  if command -v dms >/dev/null 2>&1; then
    dms restart || true
  fi
}
