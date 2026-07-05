#!/bin/sh
# OpenWrt Telegram Bot Panel - Production Installer
# Compatible with OpenWrt 23.x / 24.x
# Strict POSIX compliant BusyBox ash

set -e

# Configuration
BASE_DIR="/usr/share/owrt-tg-bot"
CONF_DIR="/etc/owrt-tg-bot"
INIT_DIR="/etc/init.d"
LOG_FILE="/var/log/owrt-tg-bot.log"
STATE_DIR="/var/run/owrt-tg-bot"

# Text Styling
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { printf "${GREEN}[INFO]${NC} %s\n" "$1"; }
log_warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
log_err()  { printf "${RED}[ERROR]${NC} %s\n" "$1"; exit 1; }

# 1. Environment and Architecture Validation
log_info "Validating environment..."
if [ ! -f /etc/openwrt_release ]; then
    log_err "This system is not running OpenWrt. Installation aborted."
fi

. /etc/openwrt_release
OS_VER=$(echo "$DISTRIB_RELEASE" | cut -d. -f1)

if [ "$OS_VER" != "23" ] && [ "$OS_VER" != "24" ]; then
    log_warn "Untested OpenWrt version: $DISTRIB_RELEASE. Proceeding with caution."
fi

# 2. Package Dependency Installation
log_info "Updating package lists and checking dependencies..."
if command -v apk >/dev/null 2>&1; then
    PKG_MGR="apk"
    apk update
else
    PKG_MGR="opkg"
    opkg update
fi

DEPENDENCIES="lua curl uci ubus jsonfilter libuci-lua libubus-lua lua-cjson"

for pkg in $DEPENDENCIES; do
    if [ "$PKG_MGR" = "apk" ]; then
        if ! apk info -e "$pkg" >/dev/null 2>&1; then
            log_info "Installing $pkg via apk..."
            apk add "$pkg" || log_err "Failed to install $pkg"
        fi
    else
        if ! opkg list-installed | grep -q "^$pkg "; then
            log_info "Installing $pkg via opkg..."
            opkg install "$pkg" || log_err "Failed to install $pkg"
        fi
    fi
done

# 3. Directory Layout Creation
log_info "Creating deployment directory matrix..."
mkdir -p "$BASE_DIR"
mkdir -p "$BASE_DIR/core"
mkdir -p "$BASE_DIR/modules"
mkdir -p "$BASE_DIR/keyboards"
mkdir -p "$BASE_DIR/lang"
mkdir -p "$BASE_DIR/plugins"
mkdir -p "$BASE_DIR/tmp"
mkdir -p "$CONF_DIR"
mkdir -p "$STATE_DIR"

touch "$LOG_FILE"
chmod 644 "$LOG_FILE"

# 4. Deploying Files from Installation Directory
log_info "Deploying engine modules..."
CURRENT_DIR=$(dirname "$(readlink -f "$0")")

# Check and copy components safely
deploy_file() {
    src="$1"
    dst="$2"
    perms="$3"
    if [ -f "$src" ]; then
        cp -f "$src" "$dst"
        chmod "$perms" "$dst"
    else
        log_err "Required source file missing: $src"
    fi
}

deploy_file "$CURRENT_DIR/config.conf" "$CONF_DIR/config.conf" 600

# Deploy system trees
for folder in core modules keyboards lang plugins; do
    if [ -d "$CURRENT_DIR/$folder" ]; then
        cp -r "$CURRENT_DIR/$folder/"* "$BASE_DIR/$folder/" 2>/dev/null || true
    fi
done

# Set permissions for source scripts
find "$BASE_DIR" -type f -name "*.lua" -exec chmod 644 {} \;
find "$BASE_DIR" -type f -name "*.sh" -exec chmod 755 {} \;

# Deploy Lifecycle Scripts
deploy_file "$CURRENT_DIR/uninstall.sh" "$BASE_DIR/uninstall.sh" 755
deploy_file "$CURRENT_DIR/update.sh" "$BASE_DIR/update.sh" 755
deploy_file "$CURRENT_DIR/init.d/owrt-tg-bot" "$INIT_DIR/owrt-tg-bot" 755

# 5. Service Configuration and Activation
log_info "Enabling and starting OpenWrt Telegram Bot Panel service..."
"$INIT_DIR/owrt-tg-bot" enable
"$INIT_DIR/owrt-tg-bot" start

log_info "=========================================================="
printf "${GREEN}Installation completed successfully!${NC}\n"
log_info "Please configure your Telegram Bot credentials here:"
printf "${BLUE}  $CONF_DIR/config.conf${NC}\n"
log_info "After configuring, restart the agent using:"
printf "${BLUE}  $INIT_DIR/owrt-tg-bot restart${NC}\n"
log_info "=========================================================="

exit 0