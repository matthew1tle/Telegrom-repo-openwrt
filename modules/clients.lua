-- modules/clients.lua
-- DHCP lease listing and temporary client blocking.
--
-- The previous version only sent a wifi-level deauth (ubus del_client),
-- which just forces one disconnect - the device's radio reassociates
-- within seconds and nothing actually stayed blocked. This version adds a
-- real temporary block: a firewall rule dropping that MAC's forwarded
-- traffic, removed automatically after the chosen duration.

local helpers = require("core.helpers")
local i18n = require("core.i18n")

local M = {}

local BLOCK_COMMENT_PREFIX = "owrt-tg-bot-block-"

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

function M.is_blocked(mac)
    local out = helpers.shell("iptables -S FORWARD 2>/dev/null | grep -F " .. helpers.shq(BLOCK_COMMENT_PREFIX .. mac))
    return out ~= ""
end

function M.render()
    local clients = M.list()
    local lines = { "<b>" .. i18n.t("clients_title") .. "</b>", "" }
    if #clients == 0 then
        lines[#lines + 1] = i18n.t("clients_none")
    else
        for _, c in ipairs(clients) do
            local mark = M.is_blocked(c.mac) and "🚫 " or "• "
            lines[#lines + 1] = string.format("%s%s (%s)", mark, c.name, c.ip)
        end
    end
    return table.concat(lines, "\n"), clients
end

-- One-off wifi-level disconnect (used right when a block starts, so the
-- client drops immediately instead of waiting for its own timeout).
local function deauth(mac)
    local ifaces = helpers.trim(helpers.shell("ubus list hostapd.* 2>/dev/null"))
    local disconnected = false
    for iface_path in ifaces:gmatch("[^\r\n]+") do
        local iface = iface_path:match("^hostapd%.(.+)$")
        if iface then
            local _, ok = helpers.shell(
                "ubus call hostapd." .. helpers.shq(iface) .. " del_client "
                .. helpers.shq(string.format('{"addr":"%s","reason":5,"deauth":true}', mac))
            )
            if ok then disconnected = true end
        end
    end
    return disconnected
end

-- Remove any existing block rule(s) for this MAC (idempotent - safe to
-- call even if nothing is currently blocked).
function M.unblock(mac)
    local comment = BLOCK_COMMENT_PREFIX .. mac
    for _ = 1, 5 do
        local _, ok = helpers.shell(
            "iptables -D FORWARD -m mac --mac-source " .. helpers.shq(mac)
            .. " -m comment --comment " .. helpers.shq(comment) .. " -j DROP"
        )
        if not ok then break end
    end
end

-- Block `mac` for `minutes`, then automatically unblock. The auto-removal
-- runs as a detached background job so it doesn't tie up the bot's main
-- loop for the whole duration, and survives independently of it.
function M.block(mac, minutes)
    M.unblock(mac) -- clear any previous block first, so durations don't stack
    local comment = BLOCK_COMMENT_PREFIX .. mac
    local secs = math.floor(minutes * 60)

    local _, ok = helpers.shell(
        "iptables -I FORWARD -m mac --mac-source " .. helpers.shq(mac)
        .. " -m comment --comment " .. helpers.shq(comment) .. " -j DROP"
    )
    deauth(mac)

    helpers.shell(string.format(
        "sh -c 'sleep %d; iptables -D FORWARD -m mac --mac-source %s -m comment --comment %s -j DROP' >/dev/null 2>&1 &",
        secs, helpers.shq(mac), helpers.shq(comment)
    ))

    return ok
end

return M
