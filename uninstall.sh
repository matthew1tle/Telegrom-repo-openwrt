#!/bin/sh
# OpenWrt Telegram Bot Panel - Production Uninstaller
# Strict POSIX compliant BusyBox ash

set -e

BASE_DIR="/usr/share/owrt-tg-bot"
CONF_DIR="/etc/owrt-tg-bot"
INIT_DIR="/etc/init.d"
LOG_FILE="/var/log/owrt-tg-bot.log"
STATE_DIR="/var/run/owrt-tg-bot"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

log_info() { printf "${GREEN}[INFO]${NC} %s\n" "$1"; }
log_warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }

log_info "Stopping and disabling Telegram Bot Panel service..."
if [ -f "$INIT_DIR/owrt-tg-bot" ]; then
    "$INIT_DIR/owrt-tg-bot" stop 2>/dev/null || true
    "$INIT_DIR/owrt-tg-bot" disable 2>/dev/null || true
    rm -f "$INIT_DIR/owrt-tg-bot"
fi

log_info "Removing operational data and runtime components..."
if [ -d "$BASE_DIR" ]; then
    rm -rf "$BASE_DIR"
fi

if [ -d "$STATE_DIR" ]; then
    rm -rf "$STATE_DIR"
fi

log_warn "Do you want to delete configuration files and logs? (y/N)"
read -r answer
if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
    log_info "Purging logs and configurations..."
    rm -rf "$CONF_DIR"
    rm -f "$LOG_FILE"
else
    log_info "Preserving configuration at: $CONF_DIR"
    log_info "Preserving logs at: $LOG_FILE"
fi

log_info "Uninstallation complete."
exit 0