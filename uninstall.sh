#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

"$ROOT/scripts/uninstall-surface-dms.sh"
"$ROOT/scripts/uninstall-wvkbd.sh"
"$ROOT/scripts/uninstall-qs-hyprview.sh"

cat <<'EOF'
Removed the packaged apps and user services managed by hyprland-surface.

For selective removal, use:
- ./scripts/uninstall-surface-dms.sh
- ./scripts/uninstall-wvkbd.sh
- ./scripts/uninstall-qs-hyprview.sh

Hyprland config, Fcitx environment files, DMS settings, and SDDM system files were left in place.
EOF
