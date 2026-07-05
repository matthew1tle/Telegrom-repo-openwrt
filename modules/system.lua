-- OpenWrt Telegram Bot Panel - System Resources Infrastructure Module
-- Handles metrics computation and raw service process terminations

local helpers = require("core.helpers")
local lang = require("lang.en")

local M = {}

function M.get_cpu_usage()
    -- Parses raw `/proc/stat` snapshot lines over an explicit 200ms sleep bound interval
    local function get_stats()
        local line = helpers.read_file("/proc/stat")
        if not line then return 0, 0 end
        local user, nice, system, idle, iowait, irq, softirq = line:match("cpu%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)")
        if not user then return 0, 0 end
        
        local total = tonumber(user) + tonumber(nice) + tonumber(system) + tonumber(idle) + 
                      tonumber(iowait) + tonumber(irq) + tonumber(softirq)
        local total_idle = tonumber(idle) + tonumber(iowait)
        return total, total_idle
    end

    local t1, id1 = get_stats()
    local sleep_cmd = "sleep 0.2"
    helpers.exec(sleep_cmd)
    local t2, id2 = get_stats()

    local diff_total = t2 - t1
    local diff_idle = id2 - id1

    if diff_total == 0 then return 0 end
    local pct = ((diff_total - diff_idle) / diff_total) * 100
    return math.max(0, math.min(100, pct))
end

function M.get_ram_info()
    local meminfo = helpers.read_file("/proc/meminfo") or ""
    local total = tonumber(meminfo:match("MemTotal:%s+(%d+)")) or 0
    local free = tonumber(meminfo:match("MemFree:%s+(%d+)")) or 0
    local buffered = tonumber(meminfo:match("Buffers:%s+(%d+)")) or 0
    local cached = tonumber(meminfo:match("Cached:%s+(%d+)")) or 0
    
    local available = free + buffered + cached
    local used = total - available
    
    local pct = total > 0 and (used / total) * 100 or 0
    return used * 1024, total * 1024, pct -- outputs bytes, bytes, percentage
end

function M.get_flash_info()
    -- Evaluates filesystem sizing matching root overlay boundaries
    local raw = helpers.exec("df -k /")
    local lines = {}
    for line in raw:gmatch("[^\r\n]+") do table.insert(lines, line) end
    if #lines < 2 then return 0, 0, 0 end
    
    -- Parse standard layout output parameters: Blocks, Used, Available, Use%
    local used, avail = lines[2]:match("%s+(%d+)%s+(%d+)%s+%d+%s+%d+%%")
    used = (tonumber(used) or 0) * 1024
    avail = (tonumber(avail) or 0) * 1024
    local total = used + avail
    local pct = total > 0 and (used / total) * 100 or 0
    return used, total, pct
end

function M.get_temperature()
    -- Iterates common thermal interface zone boundaries natively exposed in OpenWrt kernels
    local thermal_paths = {
        "/sys/class/thermal/thermal_zone0/temp",
        "/sys/class/hwmon/hwmon0/temp1_input",
        "/sys/class/hwmon/hwmon0/device/temp"
    }
    for _, path in ipairs(thermal_paths) do
        local raw = helpers.read_file(path)
        if raw then
            local temp = tonumber(raw) or 0
            if temp > 1000 then temp = temp / 1000 end -- converts mC to standard degrees
            return temp
        end
    end
    return 0
end

function M.get_metrics_summary()
    local cpu = M.get_cpu_usage()
    local ram_used, ram_total, ram_pct = M.get_ram_info()
    local flash_used, flash_total, flash_pct = M.get_flash_info()
    local temp = M.get_temperature()
    local loadavg = helpers.read_file("/proc/loadavg") or "0.00 0.00 0.00"
    loadavg = loadavg:match("^(%d+%.%d+%s+%d+%.%d+%s+%d+%.%d+)") or "N/A"
    
    -- Parses raw runtime uptime counters safely
    local uptime_raw = helpers.read_file("/proc/uptime") or "0 0"
    local uptime_secs = tonumber(uptime_raw:match("^(%d+%.?%d*)")) or 0
    local days = math.floor(uptime_secs / 86400)
    local hours = math.floor((uptime_secs % 86400) / 3600)
    local mins = math.floor((uptime_secs % 3600) / 60)
    local uptime_str = string.format("%dd %dh %dm", days, hours, mins)

    local res = string.format(
        "%s\n\n" ..
        "%s`%.1f%%`\n" ..
        "%s`%s / %s (%.1f%%)`\n" ..
        "%s`%s / %s (%.1f%%)`\n" ..
        "%s`%.1f °C`\n" ..
        "%s`%s`\n" ..
        "%s`%s`",
        lang.get("sys_title"),
        lang.get("sys_cpu"), cpu,
        lang.get("sys_ram"), helpers.format_bytes(ram_used), helpers.format_bytes(ram_total), ram_pct,
        lang.get("sys_flash"), helpers.format_bytes(flash_used), helpers.format_bytes(flash_total), flash_pct,
        lang.get("sys_temp"), temp,
        lang.get("sys_load"), loadavg,
        lang.get("sys_uptime"), uptime_str
    )
    return res
end

function M.execute_reboot()
    helpers.exec("ubus call system reboot")
end

function M.execute_shutdown()
    helpers.exec("poweroff")
end

return M