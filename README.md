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