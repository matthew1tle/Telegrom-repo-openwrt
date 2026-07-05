-- OpenWrt Telegram Bot Panel - Telemetry Alerts Core Plugin Module
-- Watches resource state structures and tracks newly associated station lease tables

local helpers = require("core.helpers")
local telegram = require("core.telegram")
local lang = require("lang.en")
local logger = require("core.logger")

local system = require("modules.system")
local clients = require("modules.clients")

local M = {}

local thresholds = {}
local target_chat_ids = {}
local tracking_state_file = "/var/run/owrt-tg-bot/alert_clients.json"

function M.init(monitor_config, allowed_chats)
    thresholds.temp = tonumber(monitor_config.alert_temp_threshold) or 75
    thresholds.ram  = tonumber(monitor_config.alert_ram_threshold) or 90
    thresholds.notify_clients = tonumber(monitor_config.alert_notify_new_client) or 1

    for id in string.gmatch(allowed_chats or "", "([^,]+)") do
        local trimmed = id:gsub("^%s*(.-)%s*$", "%1")
        if trimmed ~= "" then table.insert(target_chat_ids, trimmed) end
    end
end

local function broadcast_alert(text)
    for _, chat_id in ipairs(target_chat_ids) do
        telegram.send_message(chat_id, text)
    end
end

function M.check_thresholds()
    -- Check Module 1: Thermal Metrics Pipeline
    local current_temp = system.get_temperature()
    if current_temp > 0 and current_temp >= thresholds.temp then
        logger.warn(string.format("Threshold triggered: System temp running high at %.1f C", current_temp))
        broadcast_alert(string.format(lang.get("alert_high_temp"), tostring(current_temp)))
    end

    -- Check Module 2: Memory Starvation Processing
    local _, _, ram_pct = system.get_ram_info()
    if ram_pct >= thresholds.ram then
        logger.warn(string.format("Threshold triggered: System memory usage critical at %.1f%%", ram_pct))
        broadcast_alert(string.format(lang.get("alert_high_ram"), string.format("%.1f", ram_pct)))
    end

    -- Check Module 3: Active Station Client Map Differentiation
    if thresholds.notify_clients == 1 then
        local current_clients = clients.get_connected_clients()
        local raw_historical = helpers.read_file(tracking_state_file)
        local historical = helpers.json_decode(raw_historical)

        local newly_identified = {}
        local running_history = {}

        for mac, info in pairs(current_clients) do
            running_history[mac] = true
            if not historical[mac] then
                table.insert(newly_identified, info)
            end
        end

        -- Notify structural alert parameters if true mapping variants found
        if #newly_identified > 0 and next(historical) ~= nil then
            for _, client in ipairs(newly_identified) do
                logger.notice(string.format("New client network entry parsed: %s (%s)", client.hostname, client.ip))
                broadcast_alert(string.format(lang.get("alert_new_client"), client.hostname, client.ip, client.mac:upper()))
            end
        end

        -- Save state
        helpers.write_file(tracking_state_file, helpers.json_encode(running_history))
    end
end

return M