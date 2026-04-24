#!/usr/bin/env bash
set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

remove_tree "$HOME/.config/DankMaterialShell/plugins/surface-dms"
restart_dms_if_present

cat <<'EOF'
Removed the Surface Tablet Controls DMS plugin.
EOF
