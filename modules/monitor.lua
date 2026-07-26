-- modules/monitor.lua
-- Instantaneous network throughput: two /proc/net/dev reads a second apart,
-- turned into a rate. Cheap enough to call every time the menu is opened.

local helpers = require("core.helpers")
local i18n = require("core.i18n")

local M = {}

local WAN_IFACE_CANDIDATES = { "wan", "eth1", "pppoe-wan", "eth0.2" }

local function read_bytes(iface)
    local content = helpers.read_file("/proc/net/dev") or ""
    for line in content:gmatch("[^\r\n]+") do
        local name, rx, tx = line:match("^%s*([%w%.%-]+):%s*(%d+)%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+(%d+)")
        if name == iface then
            return tonumber(rx), tonumber(tx)
        end
    end
    return nil, nil
end

local function detect_iface()
    -- Prefer whatever OpenWrt's uci says the wan interface device is.
    local uci_dev = helpers.trim(helpers.shell("uci get network.wan.device 2>/dev/null"))
    if uci_dev ~= "" then return uci_dev end
    for _, candidate in ipairs(WAN_IFACE_CANDIDATES) do
        local rx = select(1, read_bytes(candidate))
        if rx then return candidate end
    end
    return "eth1"
end

local function human_rate(bytes_per_sec)
    if bytes_per_sec > 1024 * 1024 then
        return string.format("%.2f MB", bytes_per_sec / (1024 * 1024))
    elseif bytes_per_sec > 1024 then
        return string.format("%.1f KB", bytes_per_sec / 1024)
    end
    return string.format("%d B", bytes_per_sec)
end

function M.render()
    local iface = detect_iface()
    local rx1, tx1 = read_bytes(iface)
    if not rx1 then
        return "<b>" .. i18n.t("network_title") .. "</b>\n\n" .. i18n.t("error_generic")
    end
    os.execute("sleep 1")
    local rx2, tx2 = read_bytes(iface)

    local rx_rate = human_rate(math.max(0, (rx2 or rx1) - rx1))
    local tx_rate = human_rate(math.max(0, (tx2 or tx1) - tx1))

    local lines = {
        "<b>" .. i18n.t("network_title") .. "</b> (" .. iface .. ")",
        "",
        i18n.t("network_rx", { value = rx_rate }),
        i18n.t("network_tx", { value = tx_rate }),
    }
    return table.concat(lines, "\n")
end

return M
