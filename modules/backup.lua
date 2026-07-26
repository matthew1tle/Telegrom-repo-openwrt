-- modules/backup.lua
-- New in v1.1: on-demand configuration backup and restore, driven entirely
-- from Telegram. Uses OpenWrt's own `sysupgrade -b`, so the resulting
-- archive is the same format `sysupgrade -r` already knows how to restore.

local helpers = require("core.helpers")
local logger = require("core.logger")
local telegram = require("core.telegram")
local i18n = require("core.i18n")

local M = {}

local BACKUP_DIR = "/tmp/owrt-tg-bot-backups"
local MARKER = "owrt-tg-bot-backup"

-- Create a sysupgrade backup archive and send it to the chat as a document.
function M.create(chat_id)
    helpers.shell("mkdir -p " .. BACKUP_DIR)
    local date = os.date("%Y%m%d-%H%M%S")
    local path = string.format("%s/%s-%s.tar.gz", BACKUP_DIR, MARKER, date)

    local _, ok = helpers.shell(string.format("sysupgrade -b %s", path))
    if not ok or not helpers.file_exists(path) then
        logger.error("backup failed for chat " .. tostring(chat_id))
        return false, i18n.t("backup_failed")
    end

    local caption = i18n.t("backup_done_caption", { date = date })
    telegram.send_document(chat_id, path, caption)
    os.remove(path)
    logger.info("backup sent to chat " .. tostring(chat_id))
    return true
end

-- Sanity-check that a received file looks like a real sysupgrade tar.gz
-- before we let it anywhere near `sysupgrade -r`.
local function looks_like_backup(path)
    local out, ok = helpers.shell(string.format("tar -tzf %s 2>/dev/null | head -n 5", path))
    return ok and out ~= ""
end

-- Restore from a local file path (already downloaded from Telegram by the
-- router when a document arrives while state.awaiting == "restore_file").
function M.restore(path)
    if not helpers.file_exists(path) then
        return false, "download failed"
    end
    if not looks_like_backup(path) then
        os.remove(path)
        return false, "not_a_backup"
    end

    local _, ok = helpers.shell(string.format("sysupgrade -r %s", path))
    os.remove(path)
    if not ok then
        return false, "sysupgrade -r failed"
    end
    return true
end

return M
