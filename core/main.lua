-- OpenWrt Telegram Bot Panel - Main System Process Daemon
-- Orchestrates lifecycle configurations, background monitoring, and polling loops

package.path = "/usr/share/owrt-tg-bot/?.lua;" .. package.path

local helpers = require("core.helpers")
local logger = require("core.logger")
local telegram = require("core.telegram")
local router = require("core.router")

local CONF_FILE = "/etc/owrt-tg-bot/config.conf"

local function main()
    -- 1. Initialize System Configurations
    local config = helpers.parse_config(CONF_FILE)
    if not config.telegram or not config.telegram.bot_token or config.telegram.bot_token == "" then
        io.stderr:write("CRITICAL: config.conf is missing or telegram bot_token is empty. Terminating daemon.\n")
        os.exit(1)
    end

    -- 2. Bind Log Infrastructure
    local sys_conf = config.system or {}
    logger.init(sys_conf.log_level or 6, sys_conf.log_file or "/var/log/owrt-tg-bot.log")
    logger.info("Starting OpenWrt Telegram Management Panel Core Daemon Engine...")

    -- 3. Bootstrap Telegram Network API Wrapper
    telegram.init(
        config.telegram.bot_token,
        config.telegram.allowed_chat_ids,
        config.telegram.long_polling_timeout or 5
    )

    -- 4. Load Background Active Monitors & Event Subscriptions
    local alert_worker = nil
    local has_alerts, alerts = pcall(require, "plugins.alerts")
    if has_alerts then
        alert_worker = alerts
        alert_worker.init(config.monitors or {}, config.telegram.allowed_chat_ids)
        logger.info("Background telemetry alert matrix monitoring hook attached.")
    else
        logger.warn("Core background plugins.alerts tracking framework failed to load cleanly.")
    end

    local last_update_id = 0
    local last_monitor_check = os.time()
    
    -- 5. Execute Production Polling Control Loop Lifecycle
    while true do
        -- Background Hook Execution Path
        local current_time = os.time()
        if alert_worker and (current_time - last_monitor_check >= 30) then
            pcall(alert_worker.check_thresholds)
            last_monitor_check = current_time
        end

        -- Poll Inbound Channel Queue Frames Natively
        local response = telegram.get_updates(last_update_id + 1)
        if response and response.ok and response.result then
            for _, update in ipairs(response.result) do
                last_update_id = math.max(last_update_id, tonumber(update.update_id) or 0)
                
                if update.message then
                    local status, err = pcall(router.handle_message, update.message)
                    if not status then logger.err("Exception inside message handler pipeline: " .. tostring(err)) end
                elseif update.callback_query then
                    local status, err = pcall(router.handle_callback, update.callback_query)
                    if not status then logger.err("Exception inside callback handler pipeline: " .. tostring(err)) end
                end
            end
        end

        -- Memory Cleanup Cycle (Prevents execution pool bloat over extended execution windows)
        collectgarbage("step", 10)
    end
end

-- Force execution runtime sequence containment
main()