-- OpenWrt Telegram Bot Panel - Telemetry Network Stream Interface Module
-- Calculates delta differentials for active processing networks

local helpers = require("core.helpers")

local M = {}

-- Safely read network counters from interface descriptors
local function get_wan_bytes()
    local wan_iface = helpers.get_uci_val("network", "wan", "device") or 
                     helpers.get_uci_val("network", "wan", "ifname") or "eth1"
    
    local dev_raw = helpers.read_file("/proc/net/dev") or ""
    for line in dev_raw:gmatch("[^\r\n]+") do
        if line:match(wan_iface) then
            -- Match columns: RxBytes, RxPackets ... TxBytes, TxPackets
            local rx, tx = line:match(wan_iface .. ":%s*(%d+)%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+(%d+)")
            if rx and tx then
                return tonumber(rx), tonumber(tx)
            end
        end
    end
    return 0, 0
end

function M.get_realtime_stats()
    local rx1, tx1 = get_wan_bytes()
    local t1 = os.clock()
    
    helpers.exec("sleep 1.8") -- Dynamic interval target window to hit strict ~2s execution bounds
    
    local rx2, tx2 = get_wan_bytes()
    local t2 = os.clock()
    
    local elapsed = t2 - t1
    if elapsed <= 0 then elapsed = 2.0 end
    
    local rx_speed = (rx2 - rx1) / elapsed
    local tx_speed = (tx2 - tx1) / elapsed
    
    return rx_speed, tx_speed -- Returns raw calculated bytes per second
end

return M