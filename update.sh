#!/bin/sh
# OpenWrt Telegram Bot Panel - Production Live Updater
# Strict POSIX compliant BusyBox ash

set -e

BASE_DIR="/usr/share/owrt-tg-bot"
CONF_DIR="/etc/owrt-tg-bot"
INIT_DIR="/etc/init.d"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

log_info() { printf "${GREEN}[INFO]${NC} %s\n" "$1"; }
log_err()  { printf "${RED}[ERROR]${NC} %s\n" "$1"; exit 1; }

# This script assumes it is executed from an updated directory structure (e.g., pulled from git or unpacked)
CURRENT_DIR=$(dirname "$(readlink -f "$0")")

if [ ! -d "$BASE_DIR" ] || [ ! -f "$INIT_DIR/owrt-tg-bot" ]; then
    log_err "Application is not installed. Please run install.sh instead."
fi

log_info "Pausing Telegram Bot Panel service during update..."
"$INIT_DIR/owrt-tg-bot" stop

log_info "Syncing module updates..."
for folder in core modules keyboards lang plugins; do
    if [ -d "$CURRENT_DIR/$folder" ]; then
        mkdir -p "$BASE_DIR/$folder"
        cp -r "$CURRENT_DIR/$folder/"* "$BASE_DIR/$folder/" 2>/dev/null || true
    fi
done

# Ensure operational scripts are refreshed
if [ -f "$CURRENT_DIR/uninstall.sh" ]; then cp -f "$CURRENT_DIR/uninstall.sh" "$BASE_DIR/uninstall.sh" && chmod 755 "$BASE_DIR/uninstall.sh"; fi
if [ -f "$CURRENT_DIR/update.sh" ]; then cp -f "$CURRENT_DIR/update.sh" "$BASE_DIR/update.sh" && chmod 755 "$BASE_DIR/update.sh"; fi

# Update init script layout if modified
if [ -f "$CURRENT_DIR/init.d/owrt-tg-bot" ]; then
    cp -f "$CURRENT_DIR/init.d/owrt-tg-bot" "$INIT_DIR/owrt-tg-bot"
    chmod 755 "$INIT_DIR/owrt-tg-bot"
fi

# Permissions sanity check
find "$BASE_DIR" -type f -name "*.lua" -exec chmod 644 {} \;
find "$BASE_DIR" -type f -name "*.sh" -exec chmod 755 {} \;

log_info "Restarting updated Telegram Bot Panel engine..."
"$INIT_DIR/owrt-tg-bot" start

log_info "Update applied successfully."
exit 0