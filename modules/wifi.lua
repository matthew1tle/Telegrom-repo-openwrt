-- modules/wifi.lua
-- Lists wireless radios/SSIDs from uci and lets the user toggle them, and
-- change SSID/password, from Telegram.
--
-- IMPORTANT: uci section names for wifi-ifaces look like "@wifi-iface[0]".
-- The "[0]" is a shell glob character class - interpolating it unquoted
-- into a shell command is what silently broke every toggle before: the
-- command either glob-expanded wrong or was dropped depending on the
-- shell, so `uci set`/`uci get` quietly did nothing. Every section name
-- below goes through helpers.shq() before it touches a shell command.

local helpers = require("core.helpers")
local i18n = require("core.i18n")

local M = {}

function M.list()
    local out = helpers.shell("uci show wireless 2>/dev/null")
    local radios = {}
    local seen = {}
    for line in out:gmatch("[^\r\n]+") do
        local section = line:match("^wireless%.([^=]+)=wifi%-iface$")
        if section and not seen[section] then
            seen[section] = true
            local ssid = helpers.trim(helpers.shell("uci -q get wireless." .. helpers.shq(section) .. ".ssid"))
            local disabled = helpers.trim(helpers.shell("uci -q get wireless." .. helpers.shq(section) .. ".disabled"))
            radios[#radios + 1] = {
                name = (ssid ~= "" and ssid) or section,
                section = section,
                disabled = (disabled == "1"),
            }
        end
    end
    return radios
end

function M.get(section)
    local ssid = helpers.trim(helpers.shell("uci -q get wireless." .. helpers.shq(section) .. ".ssid"))
    local disabled = helpers.trim(helpers.shell("uci -q get wireless." .. helpers.shq(section) .. ".disabled"))
    return { name = (ssid ~= "" and ssid) or section, section = section, disabled = (disabled == "1") }
end

function M.render()
    local radios = M.list()
    local lines = { "<b>" .. i18n.t("wifi_title") .. "</b>", "" }
    for _, r in ipairs(radios) do
        lines[#lines + 1] = i18n.t(r.disabled and "wifi_disabled" or "wifi_enabled", { name = r.name })
    end
    return table.concat(lines, "\n"), radios
end

function M.toggle(section)
    local disabled = helpers.trim(helpers.shell("uci -q get wireless." .. helpers.shq(section) .. ".disabled"))
    local new_val = (disabled == "1") and "0" or "1"
    local _, ok1 = helpers.shell("uci set wireless." .. helpers.shq(section) .. ".disabled=" .. helpers.shq(new_val))
    local _, ok2 = helpers.shell("uci commit wireless")
    helpers.shell("wifi reload >/dev/null 2>&1 &")
    return ok1 and ok2, (new_val == "1")
end

-- SSID: 1-32 bytes, no control characters.
function M.set_ssid(section, new_ssid)
    new_ssid = helpers.trim(new_ssid or "")
    if new_ssid == "" or #new_ssid > 32 then
        return false, "invalid_length"
    end
    local _, ok = helpers.shell("uci set wireless." .. helpers.shq(section) .. ".ssid=" .. helpers.shq(new_ssid))
    helpers.shell("uci commit wireless")
    helpers.shell("wifi reload >/dev/null 2>&1 &")
    return ok
end

-- WPA2/3 PSK: 8-63 characters. Assumes the interface already has a psk-
-- based encryption mode configured (the OpenWrt default for a private
-- network) - this only rotates the passphrase, it doesn't change
-- encryption mode.
function M.set_password(section, new_password)
    new_password = new_password or ""
    if #new_password < 8 or #new_password > 63 then
        return false, "invalid_length"
    end
    local _, ok = helpers.shell("uci set wireless." .. helpers.shq(section) .. ".key=" .. helpers.shq(new_password))
    helpers.shell("uci commit wireless")
    helpers.shell("wifi reload >/dev/null 2>&1 &")
    return ok
end

return M
