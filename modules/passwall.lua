-- OpenWrt Telegram Bot Panel - Passwall2 Management Module
-- Interfaces safely with Passwall init and UCI configuration matrices

local helpers = require("core.helpers")
local lang = require("lang.en")

local M = {}

function M.get_status()
    -- Check if passwall control process framework handles are active
    local tcp_status = helpers.exec("pgrep -f passwall") ~= ""
    local running = false
    
    -- Evaluate operational structural components through standard sysinit hooks
    local init_check = helpers.exec("/etc/init.d/passwall status 2>/dev/null")
    if init_check:match("running") or tcp_status then
        running = true
    end

    local mode = helpers.get_uci_val("passwall", "main", "tcp_node", "None")
    local enabled = helpers.get_uci_val("passwall", "main", "enabled", "0") == "1"

    return {
        enabled = enabled,
        running = running,
        mode = mode
    }
end

function M.get_summary()
    local status = M.get_status()
    local status_icon = status.running and "🟢" or "🔴"
    local status_text = status.running and "RUNNING" or "STOPPED"
    local config_text = status.enabled and lang.get("enabled") or lang.get("disabled")

    return string.format(
        "%s\n\n" ..
        "*Service Status:* %s `%s`\n" ..
        "*UCI Configuration:* `%s`\n" ..
        "%s`%s`",
        lang.get("menu_passwall"),
        status_icon, status_text,
        config_text,
        lang.get("srv_mode"), status.mode
    )
end

function M.toggle(enable)
    local val = enable and "1" or "0"
    helpers.set_uci_val("passwall", "main", "enabled", val)
    
    if enable then
        helpers.exec("/etc/init.d/passwall start")
    else
        helpers.exec("/etc/init.d/passwall stop")
    end
    return true
end

function M.restart()
    helpers.exec("/etc/init.d/passwall restart")
    return true
end

return M