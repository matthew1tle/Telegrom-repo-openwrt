-- modules/system.lua
-- CPU / RAM / flash / uptime snapshot, read straight from /proc and df so
-- there's no dependency beyond a stock BusyBox userspace.

local helpers = require("core.helpers")
local i18n = require("core.i18n")

local M = {}

local function load_average()
    local content = helpers.read_file("/proc/loadavg") or ""
    local one, five, fifteen = content:match("([%d%.]+)%s+([%d%.]+)%s+([%d%.]+)")
    return string.format("%s, %s, %s (1/5/15m)", one or "?", five or "?", fifteen or "?")
end

local function memory()
    local content = helpers.read_file("/proc/meminfo") or ""
    local total = tonumber(content:match("MemTotal:%s+(%d+)")) or 0
    local free = tonumber(content:match("MemAvailable:%s+(%d+)")) or tonumber(content:match("MemFree:%s+(%d+)")) or 0
    local used = total - free
    local percent = total > 0 and math.floor((used / total) * 100) or 0
    return used, total, percent
end

local function disk()
    local out = helpers.shell("df -k /overlay 2>/dev/null || df -k /")
    local used, total
    for line in out:gmatch("[^\r\n]+") do
        local u, avail, t = line:match("%s(%d+)%s+(%d+)%s+(%d+)%%")
        if t then
            total = tonumber(u) + tonumber(avail)
            used = tonumber(u)
        end
    end
    used = used or 0
    total = total or 1
    local percent = math.floor((used / total) * 100)
    return used, total, percent
end

local function uptime()
    local content = helpers.read_file("/proc/uptime") or "0"
    local seconds = tonumber(content:match("^(%S+)")) or 0
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    return string.format("%dd %dh %dm", days, hours, mins)
end

local function kb_to_human(kb)
    if kb > 1024 * 1024 then
        return string.format("%.1f GB", kb / (1024 * 1024))
    elseif kb > 1024 then
        return string.format("%.1f MB", kb / 1024)
    end
    return string.format("%d KB", kb)
end

-- Different SoCs expose the thermal zone at different indices/paths, so
-- try a short list of common ones instead of assuming thermal_zone0 is
-- always the CPU.
local THERMAL_PATHS = {
    "/sys/class/thermal/thermal_zone0/temp",
    "/sys/class/thermal/thermal_zone1/temp",
    "/sys/devices/virtual/thermal/thermal_zone0/temp",
}

local function cpu_temp_c()
    for _, path in ipairs(THERMAL_PATHS) do
        local content = helpers.read_file(path)
        if content then
            local raw = tonumber(helpers.trim(content))
            if raw then
                -- Kernel reports millidegrees C on most platforms (e.g.
                -- 45000 = 45.0°C); a handful report whole degrees already.
                local celsius = raw > 1000 and (raw / 1000) or raw
                return celsius
            end
        end
    end
    return nil
end

function M.render()
    local mem_used, mem_total, mem_pct = memory()
    local disk_used, disk_total, disk_pct = disk()
    local temp = cpu_temp_c()

    local lines = {
        "<b>" .. i18n.t("system_title") .. "</b>",
        "",
        i18n.t("system_cpu", { value = load_average() }),
    }
    if temp then
        lines[#lines + 1] = i18n.t("system_temp", { value = string.format("%.1f", temp) })
    end
    lines[#lines + 1] = i18n.t("system_mem", {
        used = kb_to_human(mem_used), total = kb_to_human(mem_total), percent = mem_pct,
    })
    lines[#lines + 1] = i18n.t("system_disk", {
        used = kb_to_human(disk_used), total = kb_to_human(disk_total), percent = disk_pct,
    })
    lines[#lines + 1] = i18n.t("system_uptime", { value = uptime() })
    return table.concat(lines, "\n")
end

-- Exposed for plugins/alerts.lua so thresholds can reuse the same parsing.
function M.snapshot()
    local mem_used, mem_total, mem_pct = memory()
    local disk_used, disk_total, disk_pct = disk()
    return {
        mem_percent = mem_pct,
        disk_percent = disk_pct,
        load1 = tonumber((helpers.read_file("/proc/loadavg") or "0"):match("^([%d%.]+)")) or 0,
        cpu_temp = cpu_temp_c(),
    }
end

return M
