-- modules/wifi.lua
-- Lists wireless radios/SSIDs from uci and toggles them on/off.

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
            local ssid = helpers.trim(helpers.shell(string.format("uci -q get wireless.%s.ssid", section)))
            local disabled = helpers.trim(helpers.shell(string.format("uci -q get wireless.%s.disabled", section)))
            radios[#radios + 1] = {
                name = (ssid ~= "" and ssid) or section,
                section = section,
                disabled = (disabled == "1"),
            }
        end
    end
    return radios
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
    local disabled = helpers.trim(helpers.shell(string.format("uci get wireless.%s.disabled 2>/dev/null", section)))
    local new_val = (disabled == "1") and "0" or "1"
    helpers.shell(string.format("uci set wireless.%s.disabled=%s", section, new_val))
    helpers.shell("uci commit wireless")
    helpers.shell("wifi reload >/dev/null 2>&1 &")
    return true
end

return M
