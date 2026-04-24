#!/usr/bin/env bash
set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

copy_tree "$ROOT/packages/wvkbd" "$HOME/.config/hypr/apps/wvkbd"
copy_file "$ROOT/packages/wvkbd/integration/environment.d/10-fcitx.conf" "$HOME/.config/environment.d/10-fcitx.conf"
copy_file "$ROOT/packages/wvkbd/integration/fcitx5/conf/virtualkeyboardadapter.conf" "$HOME/.config/fcitx5/conf/virtualkeyboardadapter.conf"
copy_file "$ROOT/systemd/user/wvkbd.service" "$HOME/.config/systemd/user/wvkbd.service"
copy_file "$ROOT/systemd/user/fcitx-wvkbd-auto.service" "$HOME/.config/systemd/user/fcitx-wvkbd-auto.service"

"$HOME/.config/hypr/apps/wvkbd/build-custom.sh"

reload_user_systemd
enable_user_service wvkbd.service
enable_user_service fcitx-wvkbd-auto.service

cat <<'EOF'
Installed wvkbd package, Fcitx integration files, and user services.

Installed locations:
- app files: ~/.config/hypr/apps/wvkbd
- built binary: ~/.config/hypr/apps/wvkbd/bin/wvkbd-deskintl-custom
- Fcitx environment file: ~/.config/environment.d/10-fcitx.conf
- Fcitx virtual keyboard config: ~/.config/fcitx5/conf/virtualkeyboardadapter.conf
- user service: ~/.config/systemd/user/wvkbd.service
- user service: ~/.config/systemd/user/fcitx-wvkbd-auto.service

Verify:
- systemctl --user status wvkbd.service --no-pager
- systemctl --user status fcitx-wvkbd-auto.service --no-pager

Restart the user session if this is the first Fcitx environment install.
EOF
