-- OpenWrt Telegram Bot Panel - Internet / WAN Management Module
-- Pulls network configurations via UBUS/UCI and wraps speedtest framework binaries

local helpers = require("core.helpers")
local lang = require("lang.en")

local M = {}

function M.get_public_ip()
    -- Try secure OpenDNS trace check first (Highly reliable universal routing alternative)
    local res = helpers.exec("curl -s --connect-timeout 3 https://diagnostic.opendns.com/myip")
    local ip = res:match("(%d+%.%d+%.%d+%.%d+)") or res:match("([%a%d:]+)")
    
    -- Insecure HTTP fallback check if secure handshake times out
    if not ip or ip == "" then
        res = helpers.exec("curl -s --connect-timeout 3 http://ipinfo.io/ip")
        if res and res ~= "" then
            ip = res:gsub("%s+", "") -- Strip whitespace/newlines
        end
    end
    
    return (ip and ip ~= "") and ip or "Disconnected"
end

function M.get_wan_status()
    local status = helpers.ubus_call("network.interface.wan", "status", {}) or {}
    
    local ip_addr = "N/A"
    if status.ipv4_address and status.ipv4_address[1] then
        ip_addr = status.ipv4_address[1].address or "N/A"
    elseif status.ipv6_address and status.ipv6_address[1] then
        ip_addr = status.ipv6_address[1].address or "N/A"
    end

    local gateway = "N/A"
    if status.route then
        for _, r in ipairs(status.route) do
            if r.target == "0.0.0.0" and r.mask == 0 then
                gateway = r.nexthop or "N/A"
                break
            end
        end
    end

    local dns_servers = {}
    if status.dns_server then
        for _, dns in ipairs(status.dns_server) do
            table.insert(dns_servers, dns)
        end
    end
    local dns_str = #dns_servers > 0 and table.concat(dns_servers, ", ") or "N/A"

    local is_up = (status.up == true or ip_addr ~= "N/A") and "ONLINE" or "OFFLINE"

    return {
        wan_status = is_up,
        private_ip = ip_addr,
        gateway    = gateway,
        dns        = dns_str
    }
end

function M.get_internet_summary()
    local wan = M.get_wan_status()
    local pub_ip = M.get_public_ip()

    return string.format(
        "%s\n\n" ..
        "*WAN Status:* `%s`\n" ..
        "%s`%s`\n" ..
        "%s`%s`\n" ..
        "%s`%s`\n" ..
        "%s`%s`",
        lang.get("net_title"),
        wan.wan_status,
        lang.get("net_pub_ip"), pub_ip,
        lang.get("net_priv_ip"), wan.private_ip,
        lang.get("net_gw"), wan.gateway,
        lang.get("net_dns"), wan.dns
    )
end

function M.run_speedtest()
    -- Request an accurate 10 Megabyte chunk payload from Cloudflare global edge structures
    local test_server = "http://speed.cloudflare.com/__down?bytes=10000000"
    
    -- Tell curl to output both size_download AND time_total separated by a pipe character
    local cmd = string.format("curl -s -o /dev/null --connect-timeout 4 --max-time 15 -w '%%{size_download}|%%{time_total}' '%s'", test_server)
    local raw_output = helpers.exec(cmd)
    
    -- Extract the data components reliably
    local size_str, time_str = raw_output:match("([^|]+)|([^|]+)")
    
    local size_download = tonumber(size_str) or 0
    local elapsed = tonumber(time_str) or 0
    
    if size_download == 0 or elapsed <= 0.01 then
        return "❌ Speed test timed out or connection dropped during transmission."
    end

    -- Convert bytes/sec directly to Megabits per second
    local speed_bps = (size_download * 8) / elapsed
    local speed_mbps = speed_bps / 1000000

    return string.format(
        "🚀 *Speed Test Results (Cloudflare Edge):*\n" ..
        "*Downloaded:* `%s`\n" ..
        "*Real Time Elapsed:* `%.2fs`\n" ..
        "*Calculated Speed:* `%.2f Mbps`",
        helpers.format_bytes(size_download), elapsed, speed_mbps
    )
end

return M