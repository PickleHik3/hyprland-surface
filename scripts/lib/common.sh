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

restart_user_service() {
  local service="$1"
  systemctl --user restart "$service"
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

upsert_matugen_template() {
  local template_id="$1"
  local template_src="$2"
  local output_path="$3"
  local matugen_dir="$HOME/.config/matugen"
  local templates_dir="$matugen_dir/templates"
  local config_file="$matugen_dir/config.toml"
  local template_dest="$templates_dir/${template_id}.json"
  local escaped_template_id
  local tmp_file

  mkdir -p "$templates_dir"
  copy_file "$template_src" "$template_dest"
  touch "$config_file"

  if ! rg -q '^\[config\]$' "$config_file"; then
    printf '[config]\n\n' >> "$config_file"
  fi

  escaped_template_id="${template_id//./\\.}"
  if rg -q "^\\[templates\\.${escaped_template_id}\\]$" "$config_file"; then
    tmp_file="$(mktemp)"
    awk -v target="templates.${template_id}" '
      BEGIN { skip = 0 }
      {
        if ($0 == "[" target "]") {
          skip = 1
          next
        }
        if (skip && $0 ~ /^\[.*\]$/) {
          skip = 0
        }
        if (!skip) {
          print
        }
      }
    ' "$config_file" > "$tmp_file"
    mv "$tmp_file" "$config_file"
    printf '\n' >> "$config_file"
  fi

  cat >> "$config_file" <<EOF
[templates.${template_id}]
input_path = '${template_dest}'
output_path = '${output_path}'

EOF
}

remove_matugen_template() {
  local template_id="$1"
  local matugen_dir="$HOME/.config/matugen"
  local config_file="$matugen_dir/config.toml"
  local template_file="$matugen_dir/templates/${template_id}.json"
  local tmp_file

  remove_file "$template_file"

  if [[ ! -f "$config_file" ]]; then
    return
  fi

  tmp_file="$(mktemp)"
  awk -v target="templates.${template_id}" '
    BEGIN { skip = 0 }
    {
      if ($0 == "[" target "]") {
        skip = 1
        next
      }
      if (skip && $0 ~ /^\[.*\]$/) {
        skip = 0
      }
      if (!skip) {
        print
      }
    }
  ' "$config_file" > "$tmp_file"
  mv "$tmp_file" "$config_file"
}
