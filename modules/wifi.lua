-- OpenWrt Telegram Bot Panel - Wireless Network Management Module
-- Interfaces natively with UCI wireless configuration sub-layers

local helpers = require("core.helpers")
local lang = require("lang.en")

local M = {}

-- Parses and groups active device configurations from UCI structures
function M.get_wifi_networks()
    local networks = {}
    local raw_wifi = helpers.exec("uci show wireless")
    
    -- Parse all registered wifi-iface sections
    for section in raw_wifi:gmatch("wireless%.(@wifi%-iface%[%d+%])=wifi%-iface") do
        local device = helpers.get_uci_val("wireless", section, "device", "unknown")
        local ssid = helpers.get_uci_val("wireless", section, "ssid", "Unknown SSID")
        local key = helpers.get_uci_val("wireless", section, "key", "")
        local encryption = helpers.get_uci_val("wireless", section, "encryption", "none")
        local disabled = helpers.get_uci_val("wireless", section, "disabled", "0")
        
        -- Get hardware configuration for the host device mapping
        local channel = helpers.get_uci_val("wireless", device, "channel", "auto")
        
        table.insert(networks, {
            section = section,
            device = device,
            ssid = ssid,
            key = key,
            encryption = encryption,
            enabled = (disabled == "0"),
            channel = channel
        })
    end
    return networks
end

function M.get_wifi_summary()
    local nets = M.get_wifi_networks()
    local output = lang.get("wifi_title") .. "\n\n"
    
    for i, net in ipairs(nets) do
        local status_icon = net.enabled and "🟢" or "🔴"
        local status_text = net.enabled and lang.get("enabled") or lang.get("disabled")
        
        output = output .. string.format(
            "%s *Interface %d (%s)*\n" ..
            "┣ %s`%s`\n" ..
            "┣ %s`%s`\n" ..
            "┣ %s`%s`\n" ..
            "┣ %s`%s`\n" ..
            "┗ %s`%s`\n\n",
            status_icon, i, net.device,
            lang.get("wifi_ssid"), net.ssid,
            lang.get("wifi_pass"), (net.key ~= "" and net.key or "None"),
            lang.get("wifi_chan"), net.channel,
            lang.get("wifi_enc"), net.encryption,
            lang.get("status"), status_text
        )
    end
    
    if #nets == 0 then
        output = output .. "ℹ️ No wireless interfaces found on this device."
    end
    return output
end

function M.toggle_wifi(section, enable)
    local val = enable and "0" or "1"
    local ok = helpers.set_uci_val("wireless", section, "disabled", val)
    if ok then
        helpers.exec("/sbin/wifi reload")
    end
    return ok
end

function M.change_ssid(section, new_ssid)
    if not new_ssid or new_ssid == "" then return false end
    local ok = helpers.set_uci_val("wireless", section, "ssid", new_ssid)
    if ok then
        helpers.exec("/sbin/wifi reload")
    end
    return ok
end

function M.change_password(section, new_password)
    if not new_password or new_password == "" then return false end
    local ok = helpers.set_uci_val("wireless", section, "key", new_password)
    if ok then
        helpers.exec("/sbin/wifi reload")
    end
    return ok
end

return M