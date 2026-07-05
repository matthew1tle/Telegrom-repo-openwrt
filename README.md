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

🚀 Easy Installation Guide (For Beginners)
Welcome! You do not need to be a senior Linux engineer to set this up. Follow these simple, color-coded step-by-step instructions to get your router control panel up and running in less than 5 minutes.

🛑 STEP 0: Prerequisites (Get your Bot Details)
Open Telegram, search for @BotFather, and start a chat.

Send the command /newbot and follow the prompts to create your bot.

Copy the API Token given to you by BotFather (it looks like 123456789:ABCdefGhIJKlmNoPQRsTUVwxyZ).

Search for @userinfobot on Telegram, start it, and copy your User ID (a string of numbers like 987654321). This ensures only you can control your router.

🟢 STEP 1: Connect to Your Router
Open your terminal (macOS/Linux) or Command Prompt/PowerShell (Windows) and log into your router via SSH:

```Bash
# Replace '192.168.1.1' with your router's actual IP address if different
ssh root@192.168.1.1
```
🔵 STEP 2: Download and Install the Bot
Run this sequence of commands directly in your router's terminal. Copy and paste the block below:

```Bash
# 🟡 [COLOR: YELLOW] Navigate to the temporary shared folder
cd /tmp

# 🟢 [COLOR: GREEN] Download the latest release of the control panel
# (Replace the URL below with your actual repository URL once uploaded to GitHub)
wget [https://github.com/matthew1tle/Telegrom-repo-openwrt/archive/refs/heads/main.zip](https://github.com/username/owrt-tg-bot/archive/refs/heads/main.zip)

# 🔵 [COLOR: BLUE] Extract the files and enter the setup directory
unzip main.zip
cd Telegrom-repo-openwrt

# 🟢 [COLOR: GREEN] Make the installer executable and run it
chmod +x install.sh
./install.sh
The installer will automatically run system compatibility checks, download all required hidden dependencies, and establish the system paths.
```
🟠 STEP 3: Configure Your Credentials
Now, you must paste the Telegram values you collected in Step 0 into the configuration file:

```Bash
# 🟡 [COLOR: YELLOW] Open the configuration file using the built-in system editor
vi /etc/owrt-tg-bot/config.conf
```
Quick Editor Tip for Beginners: Press the i key on your keyboard to start typing. Use the arrow keys to navigate.

Modify these specific lines within the [telegram] block:

```Ini, TOML
[telegram]
bot_token="YOUR_TELEGRAM_BOT_TOKEN_HERE"
allowed_chat_ids="YOUR_TELEGRAM_USER_ID_HERE"
```
Once filled out, press ESC, type :wq and press Enter to save the file and exit the editor.

🟢 STEP 4: Start the Service Daemon
Your bot configuration is complete! Fire up the automated engine running in the background:

```Bash
# 🟢 [COLOR: GREEN] Enable the boot service and start the agent
/etc/init.d/owrt-tg-bot enable
/etc/init.d/owrt-tg-bot start
```
🎉 STEP 5: Launch Your Dashboard!
Go back to your Telegram client app.

Search for your newly created bot username and open the window.

Click Start or type /start.

✨ Boom! Your color-coded, complete OpenWrt dashboard matrix will instantly render via touch buttons on your screen.

🛑 Complete System Removal
If you ever want to completely clean and erase this program from your hardware system storage memory, simply log back into your router via SSH and execute:

```Bash
chmod +x /usr/share/owrt-tg-bot/uninstall.sh
/usr/share/owrt-tg-bot/uninstall.sh
```
---

This `README.md` file is now fully customized for beginner accessibility while retaining its technical blueprint documentation layout for developers. Let me know if you would like me to output the next file or if there are any additional features you want to bundle!