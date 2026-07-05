-- OpenWrt Telegram Bot Panel - Internet / WAN Management Module
-- Pulls network configurations via UBUS/UCI and wraps speedtest framework binaries

local helpers = require("core.helpers")
local lang = require("lang.en")

local M = {}

function M.get_public_ip()
    -- Uses standard Cloudflare DNS over HTTPS or structural trace endpoints
    local res = helpers.exec("curl -s --connect-timeout 3 https://1.1.1.1/cdn-cgi/trace")
    local ip = res:match("ip=(%d+%.%d+%.%d+%.%d+)")
    if not ip then
        ip = res:match("ip=([%a%d:]+)") -- Fallback IPv6 structural parse match
    end
    return ip or "Disconnected"
end

function M.get_wan_status()
    -- Queries UBUS layer directly for wan routing structures
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

    local is_up = status.up == true and "ONLINE" or "OFFLINE"

    return {
        wan_status = is_up,
        private_ip = ip_addr,
        gateway    = gateway,
        dns        = dns_str
    }
end

function M.get_internet_summary()
    local wan = M.get_wan_status()
    local pub_ip = "Checking..."
    
    if wan.wan_status == "ONLINE" then
        pub_ip = M.get_public_ip()
    else
        pub_ip = "N/A"
    end

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
    -- Lightweight speedtest execution via speedtest-cli or openwrt wget framework pipelines
    -- Uses highly optimized download samples to preserve low memory architectures
    local test_server = "http://speedtest.tele2.net/10MB.zip"
    local start_time = os.clock()
    
    local cmd = string.format("curl -s -w '%%{size_download}' -o /dev/null --max-time 15 %s", test_server)
    local size_download = tonumber(helpers.exec(cmd)) or 0
    local end_time = os.clock()
    
    local elapsed = end_time - start_time
    if size_download == 0 or elapsed <= 0 then
        return "❌ Speed test processing failed or timeout hit."
    end

    local speed_bps = (size_download * 8) / elapsed
    local speed_mbps = speed_bps / 1000000

    return string.format(
        "🚀 *Speed Test Results:*\n" ..
        "*Downloaded:* `%s`\n" ..
        "*Time Elapsed:* `%.2fs`\n" ..
        "*Calculated Speed:* `%.2f Mbps`",
        helpers.format_bytes(size_download), elapsed, speed_mbps
    )
end

return M