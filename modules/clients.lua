-- OpenWrt Telegram Bot Panel - Connected Host Management Module
-- Cross-references DHCP leases against kernel interface arp cache tables

local helpers = require("core.helpers")
local lang = require("lang.en")

local M = {}

function M.get_connected_clients()
    local clients = {}
    
    -- Step 1: Read active network structural leases mapped via DHCP configuration databases
    local dhcp_leases = {}
    local dhcp_raw = helpers.read_file("/tmp/dhcp.leases") or ""
    for line in dhcp_raw:gmatch("[^\r\n]+") do
        local ts, mac, ip, hostname, clid = line:match("(%d+)%s+([%a%d:]+)%s+(%d+%.%d+%.%d+%.%d+)%s+([^%s]+)%s+([^%s]+)")
        if mac then
            dhcp_leases[mac:lower()] = {
                ip = ip,
                hostname = (hostname == "*") and "Unknown" or hostname
            }
        end
    end

    -- Step 2: Fetch RSSI wireless signal indexes using custom dynamic runtime UBUS call blocks
    local iw_stations = {}
    local hostapd_objects = helpers.exec("ubus list hostapd.*")
    for obj_path in hostapd_objects:gmatch("[^\r\n]+") do
        local status = helpers.ubus_call(obj_path, "get_clients", {})
        if status and status.clients then
            for mac, node in pairs(status.clients) do
                -- Extends structural metrics arrays mapping station signals
                iw_stations[mac:lower()] = tonumber(node.signal) or -99
            end
        end
    end

    -- Step 3: Parse kernel standard operational ARP mapping frames
    local arp_raw = helpers.read_file("/proc/net/arp") or ""
    for line in arp_raw:gmatch("[^\r\n]+") do
        local ip, mac, dev = line:match("^(%d+%.%d+%.%d+%.%d+)%s+0x%d+%s+0x%d+%s+([%a%d:]+)%s+[^%s]+%s+([^%s]+)")
        if mac and mac ~= "00:00:00:00:00:00" then
            mac = mac:lower()
            local lease = dhcp_leases[mac] or { ip = ip, hostname = "Unknown" }
            local signal = iw_stations[mac] or nil

            clients[mac] = {
                mac = mac,
                ip = lease.ip,
                hostname = lease.hostname,
                rssi = signal,
                interface = dev
            }
        end
    end

    return clients
end

function M.get_clients_summary()
    local clients = M.get_connected_clients()
    local output = lang.get("client_title") .. "\n\n"
    
    local index = 1
    for mac, client in pairs(clients) do
        local signal_str = ""
        if client.rssi then
            signal_str = string.format(" | %s`%d dBm`", lang.get("client_rssi"), client.rssi)
        end

        output = output .. string.format(
            "%d. *%s*\n┗ 🌐 `%s` | 🪪 `%s` %s\n",
            index, client.hostname, client.ip, client.mac:upper(), signal_str
        )
        index = index + 1
    end

    if index == 1 then
        output = output .. "ℹ️ No active clients associated."
    end

    return output
end

function M.kick_client(mac)
    mac = mac:lower()
    local hostapd_objects = helpers.exec("ubus list hostapd.*")
    local executed = false
    
    -- Disconnect client across wireless hostapd radios via strict interface terminations
    for obj_path in hostapd_objects:gmatch("[^\r\n]+") do
        local res = helpers.ubus_call(obj_path, "del_client", { addr = mac, reason = 1 })
        if res then executed = true end
    end
    
    return executed
end

return M