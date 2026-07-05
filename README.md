# OpenWrt Production Telegram Bot Panel

A production-ready, modular, and exceptionally memory-efficient Telegram Management Panel for OpenWrt (23.x and 24.x) embedded routers. Written natively in **Lua** and **BusyBox ash**, utilizing native framework interfaces (`uci`, `ubus`, `apk`/`opkg`, and `procd`).

## Key Design Principles
* **Zero Engine Bloat:** Completely free of heavy scripting abstraction layers (No Python, No Node.js, No PHP). Runs inside the default system Lua runtime environment.
* **Pure Inline UI:** 100% controlled using interactive inline keyboard matrix selectors. Text command routing boundaries block all typing inputs outside of the fallback `/start` bootloader sequence.
* **Process Isolation:** Fully wrapped via OpenWrt's native init framework daemon service structures (`procd`). Includes crash recovery, respawn thresholds, and runtime execution control constraints.

## Directory Framework Layout
```text
├── config.conf             # Router Access Configuration Matrix Variables
├── install.sh              # Environment validation and Dependency installation
├── uninstall.sh            # Complete runtime asset erasure utility script
├── update.sh               # Live service hot patching update wrapper
├── LICENSE                 # Production MIT License Model
├── init.d/
│   └── owrt-tg-bot         # Native Procd init script integration file
├── core/
│   ├── main.lua            # Execution Loop & Signal Lifecycles Daemon Core
│   ├── helpers.lua         # JSON/UCI/UBUS pipeline interface wrapper
│   ├── logger.lua          # Standard system log and file append matrix
│   ├── state.lua           # Session tracking context machine layer
│   ├── telegram.lua        # POSIX cURL network communications engine
│   └── router.lua          # Main layout execution and callback map dispatcher
├── keyboards/
│   └── engine.lua          # Dynamic structural inline keyboard generator
├── lang/
│   └── en.lua              # Unified english translation schema strings map
├── modules/
│   ├── system.lua          # CPU/RAM/Flash metrics parser
│   ├── monitor.lua         # Instantaneous Delta network calculation matrix
│   ├── internet.lua        # Public tracing and integrated speedtests
│   ├── clients.lua         # DHCP lease parsing and Hostapd station kick engine
│   ├── wifi.lua            # UCI active radio network toggles
│   ├── package.lua         # Dual matching apk/opkg system interface managers
│   ├── passwall.lua        # Passwall2 framework component control wraps
│   └── singbox.lua         # Sing-box core process network pipeline lifecycles
└── plugins/
    └── alerts.lua          # Background threshold state monitoring worker
```

# ⚡ 1-Command Quick Installation Guide
No manual text editing or multi-step downloads needed. Get your panel operational in less than 60 seconds.

## 🛑 STEP 0: Prerequisites (Get your Bot Details)
Open Telegram, search for `@BotFather`, and start a chat.

Send the command `/newbot` and follow the prompts to create your bot.

Copy the API Token given to you by BotFather (it looks like `123456789:ABCdefGhIJKlmNoPQRsTUVwxyZ`).

Search for `@userinfobot` on Telegram, start it, and copy your User ID (a string of numbers like `987654321`). This ensures only you can access your router panel.

🟢 STEP 1: Connect via SSH & Execute Setup
Connect to your router using a terminal client and run this single composite command block:

```Bash
cd /tmp && \
wget -O main.zip [https://github.com/matthew1tle/Telegrom-repo-openwrt/archive/refs/heads/main.zip](https://github.com/matthew1tle/Telegrom-repo-openwrt/archive/refs/heads/main.zip) && \
unzip -o main.zip && \
cd Telegrom-repo-openwrt-main && \
chmod +x install.sh && \
./install.sh
```
💬 What Happens During Setup?
The engine checks your OpenWrt firmware version and installs the proper `lua-cjson`, `curl`, and framework dependencies automatically.

The terminal will pause and ask you to paste your `Bot Token` and your `User ID`.

The panel finishes configuration, applies MSS firewall clamping checks, and starts the automated background manager daemon.

## 🎉 STEP 2: Launch Your Dashboard!
Go back to your Telegram app.

Search for your newly created bot username and open the chat window.

Click Start or type `/start`.

### ✨ Boom! Your clean OpenWrt dashboard matrix will instantly render via interactive touch buttons right on your screen.

# 🛑 Complete System Removal
If you ever want to completely clean and erase this program from your hardware system storage memory, simply log back into your router via SSH and execute:
```Bash
chmod +x /usr/share/owrt-tg-bot/uninstall.sh
/usr/share/owrt-tg-bot/uninstall.sh
```