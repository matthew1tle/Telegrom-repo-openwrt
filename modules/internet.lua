-- modules/internet.lua
-- WAN reachability (ping), public IP lookup, and a speed test.
--
-- Speed test strategy: if a real speed test client is installed
-- (librespeed-cli or speedtest-cli - install.sh tries to install
-- librespeed-cli, since it's a small static Go binary that's a much
-- lighter fit for a router than the Python-based speedtest-cli), use it
-- for a proper download/upload/ping/server reading. Otherwise fall back
-- to a plain timed download, which only gives a rough download estimate.

local helpers = require("core.helpers")
local i18n = require("core.i18n")

local M = {}

local SPEEDTEST_FALLBACK_URL = "http://speedtest.tele2.net/10MB.zip"
local IP_LOOKUP_SERVICES = {
    "https://ifconfig.me",
    "https://icanhazip.com",
    "https://ipinfo.io/ip",
}

function M.ping(host)
    host = host or "1.1.1.1"
    local out, ok = helpers.shell("ping -c 3 -W 2 " .. helpers.shq(host))
    if not ok then
        return false, i18n.t("internet_ping_fail", { host = host })
    end
    local ms = out:match("time=([%d%.]+)")
    if not ms then
        return false, i18n.t("internet_ping_fail", { host = host })
    end
    return true, i18n.t("internet_ping_ok", { host = host, ms = ms })
end

-- Tries a short list of IP-echo services in case one is down/blocked.
function M.public_ip()
    for _, url in ipairs(IP_LOOKUP_SERVICES) do
        local out, ok = helpers.shell("curl -s -m 8 " .. helpers.shq(url))
        local ip = helpers.trim(out or "")
        if ok and ip:match("^%d+%.%d+%.%d+%.%d+$") then
            return ip
        end
    end
    return nil
end

local function parse_librespeed(json_out)
    local data = helpers.json_decode(json_out)
    local row = data and data[1]
    if not row then return nil end
    return {
        download = tonumber(row.download),
        upload = tonumber(row.upload),
        ping = tonumber(row.ping),
        server = row.server and row.server.name,
    }
end

local function parse_speedtest_cli(json_out)
    local data = helpers.json_decode(json_out)
    if not data then return nil end
    return {
        download = data.download and (tonumber(data.download) / 1000000),
        upload = data.upload and (tonumber(data.upload) / 1000000),
        ping = data.ping and tonumber(data.ping),
        server = data.server and data.server.sponsor,
    }
end

-- A real multi-directional speed test, if a client binary is available.
-- Returns a table {download, upload, ping, server} in Mbps/ms, or nil if
-- no real client is installed (caller should fall back to M.fallback_download_test()).
function M.real_speedtest()
    if helpers.shell_exists("librespeed-cli") then
        local out = helpers.shell("librespeed-cli --json 2>/dev/null")
        local result = parse_librespeed(out)
        if result then return result end
    end
    if helpers.shell_exists("speedtest-cli") then
        local out = helpers.shell("speedtest-cli --secure --json 2>/dev/null")
        local result = parse_speedtest_cli(out)
        if result then return result end
    end
    return nil
end

-- Download-only estimate via a timed curl fetch - used only when neither
-- librespeed-cli nor speedtest-cli is installed.
function M.fallback_download_test()
    local out, ok = helpers.shell(
        "curl -s -m 20 -o /dev/null -w '%{size_download} %{time_total}' " .. SPEEDTEST_FALLBACK_URL
    )
    if not ok or out == "" then return nil end
    local bytes, seconds = out:match("^(%d+)%s+([%d%.]+)")
    bytes = tonumber(bytes) or 0
    seconds = tonumber(seconds) or 1
    if seconds <= 0 then seconds = 1 end
    return (bytes * 8 / 1000000) / seconds
end

-- Runs the best available test and returns a ready-to-send text block.
function M.speedtest_render()
    local result = M.real_speedtest()
    if result and result.download then
        local lines = {
            i18n.t("internet_speedtest_download", { mbps = string.format("%.1f", result.download) }),
        }
        if result.upload then
            lines[#lines + 1] = i18n.t("internet_speedtest_upload", { mbps = string.format("%.1f", result.upload) })
        end
        if result.ping then
            lines[#lines + 1] = i18n.t("internet_speedtest_ping", { ms = string.format("%.0f", result.ping) })
        end
        if result.server then
            lines[#lines + 1] = i18n.t("internet_speedtest_server", { name = result.server })
        end
        return table.concat(lines, "\n")
    end

    local mbps = M.fallback_download_test()
    if not mbps then
        return i18n.t("error_generic")
    end
    return i18n.t("internet_speedtest_result", { mbps = string.format("%.1f", mbps) })
end

function M.render(host)
    local _, ping_line = M.ping(host)
    local ip = M.public_ip()
    local lines = {
        "<b>" .. i18n.t("network_title") .. "</b>",
        "",
        ping_line,
        ip and i18n.t("internet_public_ip", { ip = ip }) or i18n.t("internet_ip_unknown"),
    }
    return table.concat(lines, "\n")
end

return M
