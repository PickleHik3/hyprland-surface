#!/usr/bin/env bash
set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

copy_tree "$ROOT/packages/surface-dms" "$HOME/.config/DankMaterialShell/plugins/surface-dms"
restart_dms_if_present

cat <<'EOF'
Installed the Surface Tablet Controls DMS plugin.

Installed locations:
- plugin files: ~/.config/DankMaterialShell/plugins/surface-dms
- plugin manifest: ~/.config/DankMaterialShell/plugins/surface-dms/plugin.json
- main QML: ~/.config/DankMaterialShell/plugins/surface-dms/surface-tablet-controls/Main.qml

Next in DMS Settings:
1. Open Plugins.
2. Click Scan for Plugins.
3. Enable Surface Tablet Controls.
4. Click Create Missing Default Variants.
EOF
