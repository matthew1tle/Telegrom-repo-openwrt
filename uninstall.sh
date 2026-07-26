#!/bin/sh
# uninstall.sh - removes the OpenWrt Telegram Bot Panel

INSTALL_DIR=/usr/share/owrt-tg-bot
CONFIG_DIR=/etc/owrt-tg-bot
CGI_LINK=/www/cgi-bin/owrt-tg-bot-webhook

echo "=================================================="
echo " Uninstalling OpenWrt Telegram Bot Panel"
echo "=================================================="

if [ -f /etc/init.d/owrt-tg-bot ]; then
    /etc/init.d/owrt-tg-bot stop 2>/dev/null || true
    /etc/init.d/owrt-tg-bot disable 2>/dev/null || true
    rm -f /etc/init.d/owrt-tg-bot
fi

[ -L "$CGI_LINK" ] && rm -f "$CGI_LINK"
/etc/init.d/uhttpd reload >/dev/null 2>&1 || true

KEEP_CONFIG="n"
if [ -t 0 ]; then
    read -p "Keep config.conf and any backups in $CONFIG_DIR? [y/N]: " ans
    case "$ans" in
        y|Y) KEEP_CONFIG="y" ;;
    esac
fi

rm -rf "$INSTALL_DIR"

if [ "$KEEP_CONFIG" = "y" ]; then
    echo "Kept $CONFIG_DIR (remove it manually later if you no longer need it)."
else
    rm -rf "$CONFIG_DIR"
fi

rm -f /tmp/owrt-tg-bot.offset
rm -rf /tmp/owrt-tg-bot-backups /tmp/owrt-tg-bot-webhook-queue

echo "Done."
