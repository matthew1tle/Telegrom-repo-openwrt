-- modules/clients.lua
-- DHCP lease listing and client disconnect ("kick") via hostapd_cli.

local helpers = require("core.helpers")
local i18n = require("core.i18n")

local M = {}

function M.list()
    local content = helpers.read_file("/tmp/dhcp.leases") or ""
    local clients = {}
    for line in content:gmatch("[^\r\n]+") do
        -- format: <expiry> <mac> <ip> <hostname> <clientid>
        local mac, ip, name = line:match("^%d+%s+(%S+)%s+(%S+)%s+(%S+)")
        if mac then
            clients[#clients + 1] = {
                mac = mac,
                ip = ip,
                name = (name ~= "*" and name) or ip,
            }
        end
    end
    return clients
end

function M.render()
    local clients = M.list()
    local lines = { "<b>" .. i18n.t("clients_title") .. "</b>", "" }
    if #clients == 0 then
        lines[#lines + 1] = i18n.t("clients_none")
    else
        for _, c in ipairs(clients) do
            lines[#lines + 1] = string.format("• %s (%s)", c.name, c.ip)
        end
    end
    return table.concat(lines, "\n"), clients
end

-- Disconnect a station across every wifi interface that reports it
-- associated. Works for both hostapd (AP) managed radios.
function M.kick(mac)
    local ifaces = helpers.trim(helpers.shell("ubus list hostapd.* 2>/dev/null"))
    local disconnected = false
    for iface_path in ifaces:gmatch("[^\r\n]+") do
        local iface = iface_path:match("^hostapd%.(.+)$")
        if iface then
            local _, ok = helpers.shell(
                string.format("ubus call hostapd.%s del_client \"{'addr':'%s','reason':5,'deauth':true}\"", iface, mac)
            )
            if ok then disconnected = true end
        end
    end
    return disconnected
end

return M
