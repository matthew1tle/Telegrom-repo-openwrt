-- OpenWrt Telegram Bot Panel - Sing-box Proxy Core Module
-- Complete implementation wrapping service lifecycle systems

local helpers = require("core.helpers")
local lang = require("lang.en")

local M = {}

function M.get_status()
    -- Check process tracking handles natively via operational system structures
    local process_active = helpers.exec("pgrep -x sing-box") ~= ""
    local running = false
    
    local service_check = helpers.exec("/etc/init.d/sing-box status 2>/dev/null")
    if service_check:match("running") or process_active then
        running = true
    end

    local enabled = helpers.get_uci_val("sing-box", "main", "enabled", "0") == "1"
    -- Fallback config selection tracing pattern
    local user_config = helpers.get_uci_val("sing-box", "main", "config_file", "Default")

    return {
        enabled = enabled,
        running = running,
        config = user_config
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
        "*Active Config Profile:* `%s`",
        lang.get("menu_singbox"),
        status_icon, status_text,
        config_text,
        status.config
    )
end

function M.toggle(enable)
    local val = enable and "1" or "0"
    helpers.set_uci_val("sing-box", "main", "enabled", val)
    
    if enable then
        helpers.exec("/etc/init.d/sing-box start")
    else
        helpers.exec("/etc/init.d/sing-box stop")
    end
    return true
end

function M.restart()
    helpers.exec("/etc/init.d/sing-box restart")
    return true
end

return M