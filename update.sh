#!/bin/sh
# update.sh - pulls the latest release and hot-patches the running install.
# Backs up the current install first and rolls back automatically if
# anything in the update fails, so a bad download can't leave the bot dead.
set -u

REPO_ZIP_URL="https://github.com/matthew1tle/Telegrom-repo-openwrt/archive/refs/heads/main.zip"
INSTALL_DIR=/usr/share/owrt-tg-bot
CONFIG_DIR=/etc/owrt-tg-bot
CONFIG_FILE="$CONFIG_DIR/config.conf"
WORK_DIR=/tmp/owrt-tg-bot-update
ROLLBACK_ARCHIVE=/tmp/owrt-tg-bot-rollback.tar.gz

echo "=================================================="
echo " Updating OpenWrt Telegram Bot Panel"
echo "=================================================="

echo "[1/5] Backing up current install for rollback..."
tar -czf "$ROLLBACK_ARCHIVE" "$INSTALL_DIR" "$CONFIG_FILE" 2>/dev/null
if [ ! -s "$ROLLBACK_ARCHIVE" ]; then
    echo "ERROR: could not create rollback backup - aborting update." >&2
    exit 1
fi

rollback() {
    echo "!! Update failed - rolling back to the previous working install." >&2
    rm -rf "$INSTALL_DIR"
    tar -xzf "$ROLLBACK_ARCHIVE" -C /
    /etc/init.d/owrt-tg-bot restart 2>/dev/null || true
    exit 1
}

echo "[2/5] Downloading latest version..."
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR" || rollback
if ! wget -q -O main.zip "$REPO_ZIP_URL"; then
    echo "ERROR: download failed." >&2
    rollback
fi

echo "[3/5] Unpacking..."
if ! unzip -oq main.zip; then
    echo "ERROR: could not unpack archive." >&2
    rollback
fi
cd Telegrom-repo-openwrt-main 2>/dev/null || rollback

echo "[4/5] Deploying updated files (config.conf is left untouched)..."
{
    cp -r core/* "$INSTALL_DIR"/core/ &&
    cp -r keyboards/* "$INSTALL_DIR"/keyboards/ &&
    cp -r lang/* "$INSTALL_DIR"/lang/ &&
    cp -r modules/* "$INSTALL_DIR"/modules/ &&
    cp -r scripts/* "$INSTALL_DIR"/scripts/ &&
    { [ -d plugins ] && cp -r plugins/* "$INSTALL_DIR"/plugins/ || true; } &&
    cp uninstall.sh "$INSTALL_DIR"/uninstall.sh &&
    cp update.sh "$INSTALL_DIR"/update.sh &&
    cp init.d/owrt-tg-bot /etc/init.d/owrt-tg-bot
} || rollback

chmod +x "$INSTALL_DIR"/uninstall.sh "$INSTALL_DIR"/update.sh \
    "$INSTALL_DIR"/scripts/webhook_cgi.lua /etc/init.d/owrt-tg-bot
chmod 600 "$CONFIG_FILE"

echo "[5/5] Restarting service..."
/etc/init.d/owrt-tg-bot restart || rollback

cd / && rm -rf "$WORK_DIR" "$ROLLBACK_ARCHIVE"

echo "=================================================="
echo " Update complete."
echo "=================================================="
