-- plugins/alerts.lua
-- Background threshold monitor. main.lua calls check() on a timer; this
-- only sends a Telegram message when a threshold *transitions* between ok
-- and firing, so a stuck-high CPU doesn't spam the chat every loop.

local telegram = require("core.telegram")
local i18n = require("core.i18n")
local state = require("core.state")
local system = require("modules.system")
local internet = require("modules.internet")

local M = {
    enabled = true,
    cpu_percent = 90,
    mem_percent = 90,
    disk_percent = 90,
    temp_celsius = 80,
    wan_check_host = "1.1.1.1",
    check_interval_sec = 60,
    chat_ids = {},
}

function M.init(cfg)
    local a = cfg.alerts or {}
    M.enabled = (a.enabled ~= "0")
    M.cpu_percent = tonumber(a.cpu_percent) or M.cpu_percent
    M.mem_percent = tonumber(a.mem_percent) or M.mem_percent
    M.disk_percent = tonumber(a.disk_percent) or M.disk_percent
    M.temp_celsius = tonumber(a.temp_celsius) or M.temp_celsius
    M.wan_check_host = a.wan_check_host or M.wan_check_host
    M.check_interval_sec = tonumber(a.check_interval_sec) or M.check_interval_sec

    local helpers = require("core.helpers")
    M.chat_ids = helpers.split_list(cfg.telegram and cfg.telegram.allowed_chat_ids)
end

local function notify_all(text)
    for _, chat_id in ipairs(M.chat_ids) do
        telegram.send_message(chat_id, text)
    end
end

-- key transitions from false -> true only when it just started firing;
-- returns true exactly once per "becomes a problem" edge.
local function edge(key, firing)
    local was_firing = state.alert_is_firing(key)
    state.set_alert_firing(key, firing)
    return firing and not was_firing, (not firing) and was_firing
end

function M.check()
    if not M.enabled then return end

    local snap = system.snapshot()

    local cpu_firing = snap.load1 * 100 >= M.cpu_percent -- load1 as rough proxy, 1.00 ~ 100%
    local started, _ = edge("cpu", cpu_firing)
    if started then
        notify_all(i18n.t("alert_cpu_high", { value = string.format("%.2f", snap.load1) }))
    end

    local mem_firing = snap.mem_percent >= M.mem_percent
    started = edge("mem", mem_firing)
    if started then
        notify_all(i18n.t("alert_mem_high", { percent = snap.mem_percent }))
    end

    local disk_firing = snap.disk_percent >= M.disk_percent
    started = edge("disk", disk_firing)
    if started then
        notify_all(i18n.t("alert_disk_high", { percent = snap.disk_percent }))
    end

    if snap.cpu_temp then
        local temp_firing = snap.cpu_temp >= M.temp_celsius
        started = edge("temp", temp_firing)
        if started then
            notify_all(i18n.t("alert_temp_high", { value = string.format("%.1f", snap.cpu_temp) }))
        end
    end

    local wan_ok = select(1, internet.ping(M.wan_check_host))
    local wan_down_started, wan_recovered = edge("wan_down", not wan_ok)
    if wan_down_started then
        notify_all(i18n.t("alert_wan_down", { host = M.wan_check_host }))
    elseif wan_recovered then
        notify_all(i18n.t("alert_wan_recovered", { host = M.wan_check_host }))
    end
end

return M
