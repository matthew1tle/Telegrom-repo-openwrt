-- OpenWrt Telegram Bot Panel - Wireless Network Management Module
local helpers = require("core.helpers")
local M = {}

function M.get_wifi_networks()
    local networks = {}
    local raw_wifi = helpers.exec("uci show wireless")
    local sections_found = {}
    
    for section in raw_wifi:gmatch("wireless%.([^%.=]+)=wifi%-iface") do
        if not sections_found[section] then
            sections_found[section] = true
            
            local device = helpers.get_uci_val("wireless", section, "device", "unknown")
            local ssid = helpers.get_uci_val("wireless", section, "ssid", "Unknown SSID")
            local key = helpers.get_uci_val("wireless", section, "key", "")
            local encryption = helpers.get_uci_val("wireless", section, "encryption", "none")
            local disabled = helpers.get_uci_val("wireless", section, "disabled", "0")
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
    end
    return networks
end

function M.get_wifi_summary()
    local nets = M.get_wifi_networks()
    local output = "📶 *Wireless Networks Control*\n\n"
    
    for i, net in ipairs(nets) do
        local status_icon = net.enabled and "🟢" or "🔴"
        local status_text = net.enabled and "Enabled" or "Disabled"
        
        output = output .. string.format(
            "%s *Interface: %s*\n" ..
            "┣ SSID: `%s`\n" ..
            "┣ Pass: `%s`\n" ..
            "┣ Chan: `%s`\n" ..
            "┣ Enc:  `%s`\n" ..
            "┗ State: *%s*\n\n",
            status_icon, net.section,
            net.ssid, (net.key ~= "" and net.key or "None"),
            net.channel, net.encryption, status_text
        )
    end
    
    if #nets == 0 then output = output .. "ℹ️ No wireless interfaces found." end
    return output
end

function M.toggle_wifi(section, enable)
    local val = enable and "0" or "1"
    helpers.exec(string.format("uci set wireless.%s.disabled='%s' && uci commit wireless && /sbin/wifi reload", section, val))
    return true
end

function M.change_ssid(section, new_ssid)
    if not new_ssid or new_ssid == "" then return false end
    -- Safely strip wrapping single quotes if entered by user
    new_ssid = new_ssid:gsub("^'*(.-)'*$", "%1")
    helpers.exec(string.format("uci set wireless.%s.ssid='%s' && uci commit wireless && /sbin/wifi reload", section, new_ssid:gsub("'", "'\\''")))
    return true
end

function M.change_password(section, new_password)
    if not new_password or new_password == "" then return false end
    new_password = new_password:gsub("^'*(.-)'*$", "%1")
    helpers.exec(string.format("uci set wireless.%s.key='%s' && uci commit wireless && /sbin/wifi reload", section, new_password:gsub("'", "'\\''")))
    return true
end

return M