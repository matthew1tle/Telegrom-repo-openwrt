# Changelog

## v1.1.3

**Network: public IP + real speed test**
- The Network view now also shows your public IP (tried across a couple
  of IP-echo services in case one is unreachable).
- New **Speed test** button. Uses `librespeed-cli` (installed by
  `install.sh` when available - it's a small static binary, a much
  better fit for a router than the Python-based `speedtest-cli`) for a
  real download/upload/ping/server reading. Falls back to the previous
  timed-download estimate if neither client is installed.

**Bale (بله) support**
- `config.conf` now has a `platform="telegram"|"bale"` setting. Bale's
  Bot API mirrors Telegram's method names and JSON shapes at a different
  host, so this is a one-line switch - nothing else in the bot needs to
  change. `install.sh` asks which platform to set up.

## v1.1.2

**Fix: Wi-Fi toggle did nothing**
- uci section names like `@wifi-iface[0]` were being interpolated
  unquoted into shell commands. `[0]` is a shell glob character class, so
  `uci set`/`uci get` calls on wireless sections silently misbehaved -
  the bot reported "toggled" regardless of whether anything actually
  changed. Every section/MAC/etc. that touches a shell command now goes
  through a shared `helpers.shq()` quoting helper.

**Wi-Fi: proper on/off + rename + password**
- Tapping a radio now opens a detail view (name, status) with buttons to
  turn it on/off, rename the SSID, or change the password - instead of
  toggling blind on tap. The radio never disappears from the list; its
  status indicator just updates.

**Clients: real timed blocking**
- The old "kick" only sent a one-off Wi-Fi deauth, so the device just
  reconnected seconds later - access was never actually cut off. Tapping
  a client now opens a duration picker (5 min / 30 min / 1 hour). Chosen
  duration adds a firewall rule dropping that MAC's traffic, which is
  automatically removed when the timer runs out - plus a manual "unblock
  now" option.

**Packages: plain-text update list**
- New **Update list** button sends the names of every package with an
  update available as its own message, instead of only showing a count.

**Less chat clutter**
- Confirmations for button presses (toggle, block, rename, language
  change, etc.) now show as a small popup instead of a separate chat
  message. The menu is a single message that gets edited in place, so it
  doesn't get pushed around or duplicated by follow-up notifications.

**System: CPU temperature**
- Added to the System view (when the board exposes a thermal zone) and
  to the alert thresholds (`temp_celsius` in `config.conf`).

**Emoji throughout**
- Every button label and bot message now carries an emoji, all defined
  in the language files (`lang/en.lua`, `lang/fa.lua`) rather than
  hardcoded per-module, so translations stay in one place.

## v1.1.1

**Fix: translations showing raw keys (e.g. `btn_wifi`) instead of text**
- `core/i18n.lua` was looking for `lang/<code>.lua` using a path relative
  to the process's working directory. procd starts the daemon with cwd
  `/`, not the install directory, so language file loading silently
  failed and every string fell back to a two-key emergency stub -
  showing the raw key everywhere instead of translated text. Fixed by
  resolving `lang/` relative to `core/i18n.lua`'s own install location
  instead of the process cwd.

**Button-only interaction**
- `/start` is now the only typed command. `/backup` and `/logs` were
  removed as text commands - both are reachable only through the inline
  keyboard (a new **Logs** button was added to the main menu). Any other
  typed text now just re-shows the main menu instead of being parsed as
  a command.

## v1.1.0

**Security**
- `config.conf` is now `chmod 600` right after it's written (previously
  left at the default umask, which could leave the bot token
  world-readable).
- `install.sh` validates the bot token and chat ID format before writing
  them anywhere.
- Every incoming message/callback is checked against `allowed_chat_ids`
  before any module runs; unauthorized attempts are logged.

**Multi-language support**
- New `core/i18n.lua` loader. Every string in the bot goes through
  `i18n.t("key")`. Adding a language is now: drop a `lang/<code>.lua` file
  with the same keys as `lang/en.lua`, then set `language="<code>"` in
  `config.conf`. No other file needs to change.
- Added `lang/fa.lua` (Persian) alongside the existing `lang/en.lua`.
- A `/language` menu (config-driven, lists whatever's in `lang/`) lets you
  switch languages from inside Telegram without SSH.

**Webhook mode**
- `config.conf` now supports `mode="webhook"` as an alternative to
  polling, using a small uhttpd CGI handler
  (`scripts/webhook_cgi.lua`) that queues incoming updates for
  `core/main.lua` to process. Meant for routers where the constant
  long-poll connection is worth avoiding.

**Backup / restore**
- New `modules/backup.lua` and a `/backup` command (also reachable from
  the menu): runs `sysupgrade -b`, sends the archive to you as a Telegram
  document.
- Send a `.tar.gz` backup file back to the bot to restore it
  (`sysupgrade -r`), with a basic sanity check that it's actually a
  sysupgrade archive before it's applied.

**Reliability**
- `install.sh` backs up any existing installation before overwriting it.
- `update.sh` now backs up the working install first and rolls back
  automatically if the download, unpack, or deploy step fails.
- `uninstall.sh` asks before deleting `config.conf` and backups instead of
  always wiping them.
- Log rotation (`core/logger.lua`) keeps `/var/log/owrt-tg-bot.log` from
  growing unbounded on the router's flash.

**Alerts**
- `plugins/alerts.lua` now reads thresholds from `config.conf`
  (`[alerts]` section: CPU/RAM/flash percent, WAN check host, interval)
  and only sends a message on state *transitions* (ok → firing, firing →
  ok), instead of repeating on every check.

**Housekeeping**
- Removed `.DS_Store` from the repo, added `.gitignore`.
- README rewritten in plain language.
- Added `.github/workflows/lint.yml` (shellcheck + luacheck).

## v1.0.0
Initial release: system/network/client/Wi-Fi/package modules, inline
keyboard UI, procd service integration.
