#!/bin/sh

# OpenWrt Production Telegram Bot Panel - Auto Installer
# Targets native architecture deployment patterns

set -e

echo "=================================================="
echo "🛡️  Installing OpenWrt Telegram Bot Panel"
echo "=================================================="

# 1. Detect Package Manager and Install Base System Tools
if command -v apk >/dev/null 2>&1; then
    echo "📦 Detected OpenWrt 24.x+ (apk engine). Updating repositories..."
    apk update
    apk add curl ca-bundle ca-certificates lua lua-cjson uci ubus jsonfilter libuci-lua libubus-lua unzip
elif command -v opkg >/dev/null 2>&1; then
    echo "📦 Detected OpenWrt 23.x or older (opkg engine). Updating repositories..."
    opkg update
    opkg install curl ca-bundle ca-certificates lua lua-cjson uci ubus jsonfilter libuci-lua libubus-lua unzip
else
    echo "❌ Error: Standard OpenWrt package manager not found!"
    exit 1
fi

# 2. Gather User Credentials Natively via TTY Prompt
echo ""
echo "--------------------------------------------------"
echo "🔑 Telegram API Token Configuration"
echo "--------------------------------------------------"
read -p "👉 Enter your Telegram Bot Token: " USER_BOT_TOKEN
read -p "👉 Enter your Telegram User ID (Allowed Chat ID): " USER_CHAT_ID

if [ -z "$USER_BOT_TOKEN" ] || [ -z "$USER_CHAT_ID" ]; then
    echo "❌ Error: Configuration variables cannot be blank."
    exit 1
fi

# 3. Establish System File Layout Targets
echo "📂 Constructing system directory footprints..."
mkdir -p /usr/share/owrt-tg-bot/core
mkdir -p /usr/share/owrt-tg-bot/keyboards
mkdir -p /usr/share/owrt-tg-bot/lang
mkdir -p /usr/share/owrt-tg-bot/modules
mkdir -p /usr/share/owrt-tg-bot/plugins
mkdir -p /etc/owrt-tg-bot

# 4. Migrate Working Runtime Files
echo "🚚 Deploying runtime application components..."
cp -r core/* /usr/share/owrt-tg-bot/core/
cp -r keyboards/* /usr/share/owrt-tg-bot/keyboards/
cp -r lang/* /usr/share/owrt-tg-bot/lang/
cp -r modules/* /usr/share/owrt-tg-bot/modules/
[ -d plugins ] && cp -r plugins/* /usr/share/owrt-tg-bot/plugins/ || true
cp uninstall.sh /usr/share/owrt-tg-bot/uninstall.sh
chmod +x /usr/share/owrt-tg-bot/uninstall.sh

# 5. Build Configuration Matrix File Dynamically
echo "📝 Writing structural access tokens to config block..."
cat << EOF > /etc/owrt-tg-bot/config.conf
[telegram]
bot_token="$USER_BOT_TOKEN"
allowed_chat_ids="$USER_CHAT_ID"
EOF

# 6. Establish Procd Service Daemon Init System Links
echo "⚙️ Injecting service initialization daemons..."
cp init.d/owrt-tg-bot /etc/init.d/owrt-tg-bot
chmod +x /etc/init.d/owrt-tg-bot

# 7. Enable and Start Daemon Core Engine
echo "🚀 Booting active bot background manager loops..."
/etc/init.d/owrt-tg-bot enable
/etc/init.d/owrt-tg-bot restart

echo "=================================================="
echo "🎉 Setup Complete! Go to Telegram and tap /start"
echo "=================================================="