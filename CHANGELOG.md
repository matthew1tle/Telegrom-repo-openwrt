# Changelog

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
