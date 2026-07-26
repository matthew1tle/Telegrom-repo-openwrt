#!/usr/bin/env lua
-- core/main.lua
-- Daemon entry point, started by init.d/owrt-tg-bot under procd.
--
-- Supports two delivery modes, chosen by [telegram].mode in config.conf:
--   polling  - long-polls Telegram's getUpdates. Works anywhere, no public
--              IP or TLS needed. Slightly higher idle CPU/network use.
--   webhook  - Telegram pushes updates to a public https URL. uhttpd runs
--              scripts/webhook_cgi.lua as a CGI handler that drops each
--              update as a JSON file into a queue directory; main.lua just
--              watches that directory. Lower resource use, needs a
--              reachable HTTPS endpoint (e.g. behind a reverse proxy).

package.path = package.path .. ";/usr/share/owrt-tg-bot/?.lua"

local helpers = require("core.helpers")
local logger = require("core.logger")
local i18n = require("core.i18n")
local telegram = require("core.telegram")
local router = require("core.router")
local alerts = require("plugins.alerts")

local CONFIG_PATH = "/etc/owrt-tg-bot/config.conf"
local OFFSET_FILE = "/tmp/owrt-tg-bot.offset"
local WEBHOOK_QUEUE_DIR = "/tmp/owrt-tg-bot-webhook-queue"

local function load_config()
    local cfg, err = helpers.parse_conf(CONFIG_PATH)
    if not cfg then
        io.stderr:write("FATAL: could not read " .. CONFIG_PATH .. ": " .. tostring(err) .. "\n")
        os.exit(1)
    end
    return cfg
end

local function read_offset()
    local content = helpers.read_file(OFFSET_FILE)
    return content and tonumber(helpers.trim(content)) or 0
end

local function write_offset(offset)
    helpers.write_file(OFFSET_FILE, tostring(offset))
end

local function polling_loop()
    telegram.delete_webhook() -- make sure webhook mode isn't also enabled
    local offset = read_offset()
    logger.info("starting in polling mode (offset=" .. offset .. ")")

    local last_alert_check = 0
    while true do
        local updates = telegram.get_updates(offset, 25)
        if updates then
            for _, update in ipairs(updates) do
                router.dispatch(update)
                offset = update.update_id + 1
            end
            if #updates > 0 then write_offset(offset) end
        else
            os.execute("sleep 2")
        end

        if os.time() - last_alert_check >= alerts.check_interval_sec then
            alerts.check()
            last_alert_check = os.time()
        end
    end
end

local function webhook_loop(webhook_url)
    helpers.shell("mkdir -p " .. WEBHOOK_QUEUE_DIR)
    telegram.set_webhook(webhook_url)
    logger.info("starting in webhook mode (" .. webhook_url .. ")")

    local last_alert_check = 0
    while true do
        local listing = helpers.shell("ls " .. WEBHOOK_QUEUE_DIR .. " 2>/dev/null")
        for filename in listing:gmatch("[^\r\n]+") do
            local path = WEBHOOK_QUEUE_DIR .. "/" .. filename
            local content = helpers.read_file(path)
            os.remove(path)
            if content then
                local update = helpers.json_decode(content)
                if update then router.dispatch(update) end
            end
        end

        os.execute("sleep 1")

        if os.time() - last_alert_check >= alerts.check_interval_sec then
            alerts.check()
            last_alert_check = os.time()
        end
    end
end

local function main()
    local cfg = load_config()

    logger.init(cfg)
    i18n.load(cfg.general and cfg.general.language or "en")
    router.init(cfg)
    alerts.init(cfg)

    local token = cfg.telegram and cfg.telegram.bot_token
    if not token or token == "" then
        logger.error("bot_token missing from config.conf - aborting")
        os.exit(1)
    end
    telegram.init(token)

    local mode = (cfg.telegram and cfg.telegram.mode) or "polling"
    if mode == "webhook" then
        local url = cfg.telegram.webhook_url
        if not url or url == "" then
            logger.error("mode=webhook but webhook_url is empty - falling back to polling")
            polling_loop()
        else
            webhook_loop(url)
        end
    else
        polling_loop()
    end
end

main()
