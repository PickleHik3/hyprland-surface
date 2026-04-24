#!/usr/bin/env bash
set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

copy_tree_merge "$ROOT/packages/hypr" "$HOME/.config/hypr"

cat <<'EOF'
Merged the packaged Hyprland config into ~/.config/hypr.

Installed locations:
- config root: ~/.config/hypr
- main config: ~/.config/hypr/hyprland.conf
- packaged includes: ~/.config/hypr/conf
- DMS config snippets: ~/.config/hypr/dms

Review the copied files before reloading Hyprland if you already maintain local overrides.
EOF
