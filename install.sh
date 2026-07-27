#!/bin/sh
# install.sh - OpenWrt Telegram Bot Panel installer
set -e

INSTALL_DIR=/usr/share/owrt-tg-bot
CONFIG_DIR=/etc/owrt-tg-bot
CONFIG_FILE="$CONFIG_DIR/config.conf"
BACKUP_DIR="$CONFIG_DIR/pre-install-backups"

echo "=================================================="
echo " Installing OpenWrt Telegram Bot Panel"
echo "=================================================="

# 1. Package manager detection + dependency install ------------------------

if command -v apk >/dev/null 2>&1; then
    echo "[1/9] Detected apk (OpenWrt 24.x+). Installing dependencies..."
    apk update
    apk add curl ca-bundle ca-certificates lua lua-cjson uci ubus jsonfilter \
        libuci-lua libubus-lua unzip tar
    apk add librespeed-cli 2>/dev/null || true
elif command -v opkg >/dev/null 2>&1; then
    echo "[1/9] Detected opkg (OpenWrt 23.x or older). Installing dependencies..."
    opkg update
    opkg install curl ca-bundle ca-certificates lua lua-cjson uci ubus jsonfilter \
        libuci-lua libubus-lua unzip tar
    opkg install librespeed-cli 2>/dev/null || true
else
    echo "ERROR: no supported package manager (apk/opkg) found." >&2
    exit 1
fi

# 2. Back up any existing installation --------------------------------------

if [ -d "$INSTALL_DIR" ] || [ -f "$CONFIG_FILE" ]; then
    echo "[2/9] Existing installation found - backing it up before overwriting..."
    mkdir -p "$BACKUP_DIR"
    stamp=$(date +%Y%m%d-%H%M%S)
    tar -czf "$BACKUP_DIR/pre-install-$stamp.tar.gz" \
        "$INSTALL_DIR" "$CONFIG_FILE" 2>/dev/null || true
    echo "    -> saved to $BACKUP_DIR/pre-install-$stamp.tar.gz"
else
    echo "[2/9] No existing installation found."
fi

# 3/9. Platform selection ------------------------------------------------------

echo ""
echo "--------------------------------------------------"
echo " Platform"
echo "--------------------------------------------------"
echo "  1) Telegram (default)"
echo "  2) Bale (بله)"
read -p "Choose [1]: " PLATFORM_CHOICE
USER_PLATFORM="telegram"
BOT_NAME="Telegram"
if [ "$PLATFORM_CHOICE" = "2" ]; then
    USER_PLATFORM="bale"
    BOT_NAME="Bale"
fi

# 4/9. Collect and validate credentials ---------------------------------------

echo ""
echo "--------------------------------------------------"
echo " $BOT_NAME bot credentials"
echo "--------------------------------------------------"
if [ "$USER_PLATFORM" = "bale" ]; then
    echo "Get a token from Bale's @BotFather-equivalent bot and your numeric"
    echo "user ID the same way you would on Telegram."
else
    echo "Get a token from @BotFather and your numeric chat ID from @userinfobot."
fi
echo ""

while true; do
    read -p "Bot token: " USER_BOT_TOKEN
    case "$USER_BOT_TOKEN" in
        [0-9]*:*) break ;;
        *) echo "  That doesn't look like a bot token (expected digits:letters, e.g. 123456:ABC-def). Try again." ;;
    esac
done

while true; do
    read -p "Your Telegram user ID (numeric): " USER_CHAT_ID
    case "$USER_CHAT_ID" in
        ''|*[!0-9,\ ]*) echo "  User ID must be numeric (comma-separate multiple IDs). Try again." ;;
        *) break ;;
    esac
done

# 5/9. Language selection ------------------------------------------------------

echo ""
echo "--------------------------------------------------"
echo " Language"
echo "--------------------------------------------------"
echo "Available languages (drop a new lang/<code>.lua file to add more):"
i=0
lang_choices=""
for f in lang/*.lua; do
    code=$(basename "$f" .lua)
    lang_choices="$lang_choices $code"
    echo "  - $code"
done
read -p "Language code [en]: " USER_LANG
USER_LANG=${USER_LANG:-en}
if ! echo "$lang_choices" | grep -qw "$USER_LANG"; then
    echo "  Unknown code, defaulting to en."
    USER_LANG=en
fi

# 6/9. Delivery mode ------------------------------------------------------------

echo ""
echo "--------------------------------------------------"
echo " Update delivery mode"
echo "--------------------------------------------------"
echo "  1) polling  - works anywhere, no public URL needed (default)"
echo "  2) webhook  - lower resource use, requires a reachable https URL"
read -p "Choose [1]: " MODE_CHOICE
USER_MODE="polling"
USER_WEBHOOK_URL=""
if [ "$MODE_CHOICE" = "2" ]; then
    USER_MODE="webhook"
    read -p "Public HTTPS webhook URL (e.g. https://your-domain/cgi-bin/owrt-tg-bot-webhook): " USER_WEBHOOK_URL
    if [ -z "$USER_WEBHOOK_URL" ]; then
        echo "  No URL given - falling back to polling mode."
        USER_MODE="polling"
    fi
fi

# 7-9/9. Deploy files, write config, install + start service -------------------------------------------------------------

echo ""
echo "[7/9] Creating directory layout..."
mkdir -p "$INSTALL_DIR"/core "$INSTALL_DIR"/keyboards "$INSTALL_DIR"/lang \
    "$INSTALL_DIR"/modules "$INSTALL_DIR"/plugins "$INSTALL_DIR"/scripts
mkdir -p "$CONFIG_DIR"

echo "[7/9] Copying application files..."
cp -r core/* "$INSTALL_DIR"/core/
cp -r keyboards/* "$INSTALL_DIR"/keyboards/
cp -r lang/* "$INSTALL_DIR"/lang/
cp -r modules/* "$INSTALL_DIR"/modules/
cp -r scripts/* "$INSTALL_DIR"/scripts/
[ -d plugins ] && cp -r plugins/* "$INSTALL_DIR"/plugins/ || true
cp uninstall.sh "$INSTALL_DIR"/uninstall.sh
cp update.sh "$INSTALL_DIR"/update.sh
chmod +x "$INSTALL_DIR"/uninstall.sh "$INSTALL_DIR"/update.sh "$INSTALL_DIR"/scripts/webhook_cgi.lua

echo "[8/9] Writing configuration (platform=$USER_PLATFORM, mode=$USER_MODE, language=$USER_LANG)..."
cat << EOF > "$CONFIG_FILE"
[telegram]
bot_token="$USER_BOT_TOKEN"
allowed_chat_ids="$USER_CHAT_ID"
platform="$USER_PLATFORM"
mode="$USER_MODE"
webhook_url="$USER_WEBHOOK_URL"
webhook_port="8443"

[general]
language="$USER_LANG"

[alerts]
enabled="1"
cpu_percent="90"
mem_percent="90"
disk_percent="90"
temp_celsius="80"
check_interval_sec="60"
wan_check_host="1.1.1.1"

[logging]
max_size_kb="256"
level="info"
EOF
# Security fix: config.conf holds the bot token, so it must not be
# world- or group-readable.
chmod 600 "$CONFIG_FILE"

echo "[9/9] Installing service..."
cp init.d/owrt-tg-bot /etc/init.d/owrt-tg-bot
chmod +x /etc/init.d/owrt-tg-bot

echo "[9/9] Starting service..."
/etc/init.d/owrt-tg-bot enable
/etc/init.d/owrt-tg-bot restart

echo "=================================================="
echo " Setup complete. Open $BOT_NAME and send /start to your bot."
echo " Config file permissions: $(stat -c '%a' "$CONFIG_FILE" 2>/dev/null || echo 600) (600 expected)"
echo "=================================================="
