-- modules/internet.lua
-- WAN reachability (ping) and a quick, approximate download speed check.
-- Deliberately not a full speedtest.net client - that would pull in a much
-- heavier dependency for a number that's only meant as a rough sanity check.

local helpers = require("core.helpers")
local i18n = require("core.i18n")

local M = {}

local SPEEDTEST_URL = "http://speedtest.tele2.net/10MB.zip"

function M.ping(host)
    host = host or "1.1.1.1"
    local out, ok = helpers.shell(string.format("ping -c 3 -W 2 %s", host))
    if not ok then
        return false, i18n.t("internet_ping_fail", { host = host })
    end
    local ms = out:match("time=([%d%.]+)")
    if not ms then
        return false, i18n.t("internet_ping_fail", { host = host })
    end
    return true, i18n.t("internet_ping_ok", { host = host, ms = ms })
end

function M.speedtest()
    local start = os.time()
    local out, ok = helpers.shell(
        string.format("curl -s -m 20 -o /dev/null -w '%%{size_download} %%{time_total}' %s", SPEEDTEST_URL)
    )
    if not ok or out == "" then
        return i18n.t("error_generic")
    end
    local bytes, seconds = out:match("^(%d+)%s+([%d%.]+)")
    bytes = tonumber(bytes) or 0
    seconds = tonumber(seconds) or 1
    if seconds <= 0 then seconds = 1 end
    local mbps = (bytes * 8 / 1000000) / seconds
    return i18n.t("internet_speedtest_result", { mbps = string.format("%.1f", mbps) })
end

function M.render(host)
    local ok, line = M.ping(host)
    return "<b>" .. i18n.t("network_title") .. "</b>\n\n" .. line
end

return M
