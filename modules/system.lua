-- OpenWrt Telegram Bot Panel - System Resource Telemetry Module
-- Natively reads /proc/ and /sys/ state file trees with wide hardware compatibility

local helpers = require("core.helpers")
local lang = require("lang.en")

local M = {}

-- Safely calculates CPU computation load averages
function M.get_cpu_load()
    local load = helpers.exec("cat /proc/loadavg")
    local lav1, lav5, lav15 = load:match("([^%s]+)%s+([^%s]+)%s+([^%s]+)")
    if lav1 then
        return string.format("%s, %s, %s", lav1, lav5, lav15)
    end
    return "Unknown"
end

-- Safely reads RAM allocation boundaries across differing BusyBox engine layers
function M.get_ram_usage()
    local meminfo = helpers.exec("cat /proc/meminfo")
    local mem_total = tonumber(meminfo:match("MemTotal:%s+(%d+)")) or 0
    local mem_free = tonumber(meminfo:match("MemFree:%s+(%d+)")) or 0
    local mem_cached = tonumber(meminfo:match("Cached:%s+(%d+)")) or 0
    local mem_buffers = tonumber(meminfo:match("Buffers:%s+(%d+)")) or 0
    
    if mem_total > 0 then
        -- Calculate accurate active memory capacity mirroring the 'free' tool logic
        local mem_used = mem_total - (mem_free + mem_cached + mem_buffers)
        local pct = (mem_used / mem_total) * 100
        
        return string.format(
            "%.1f%% (%s / %s)",
            pct,
            helpers.format_bytes(mem_used * 1024),
            helpers.format_bytes(mem_total * 1024)
        )
    end
    return "Data Unavailable"
end

-- Universally scans multiple system zones for SoC temperature sensors
function M.get_cpu_temp()
    local paths = {
        "/sys/class/thermal/thermal_zone0/temp",
        "/sys/class/thermal/thermal_zone1/temp",
        "/sys/class/hwmon/hwmon0/temp1_input",
        "/sys/class/hwmon/hwmon1/device/temp1_input"
    }
    
    for _, path in ipairs(paths) do
        local raw = helpers.exec(string.format("cat %s 2>/dev/null", path))
        local temp = raw:match("(%d+)")
        if temp then
            local t = tonumber(temp)
            -- OpenWrt stores temperatures as integers scaled by 1000 (e.g., 45000 = 45°C)
            if t > 1000 then t = t / 1000 end
            if t > 0 and t < 120 then -- Sanity validation window filter
                return string.format("%.1f°C", t)
            end
        end
    end
    return "N/A"
end

-- Safely calculates remaining storage space on the primary flash partition rootfs
function M.get_flash_usage()
    local df = helpers.exec("df -k /")
    -- Parse standard secondary row data sequence from df matrix array
    local total, used, available, pct_str = df:match("\n%S+%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%%")
    
    if total then
        local t = tonumber(total) * 1024
        local u = tonumber(used) * 1024
        return string.format("%s%% (%s / %s)", pct_str, helpers.format_bytes(u), helpers.format_bytes(t))
    end
    return "Data Unavailable"
end

-- Standard engine uptime formatting logic handler
function M.get_system_uptime()
    local uptime_raw = helpers.exec("cat /proc/uptime")
    local seconds_str = uptime_raw:match("^([^%s]+)")
    local total_seconds = seconds_str and tonumber(seconds_str) or 0
    
    local days = math.floor(total_seconds / 86400)
    local hours = math.floor((total_seconds % 86400) / 3600)
    local minutes = math.floor((total_seconds % 3600) / 60)
    
    if days > 0 then
        return string.format("%dd %dh %dm", days, hours, minutes)
    else
        return string.format("%dh %dm", hours, minutes)
    end
end

function M.get_metrics_summary()
    local cpu_load = M.get_cpu_load()
    local ram_usage = M.get_ram_usage()
    local flash_usage = M.get_flash_usage()
    local cpu_temp = M.get_cpu_temp()
    local uptime = M.get_system_uptime()
    
    -- Read device name structure from standard OpenWrt system configurations block
    local model = helpers.exec("cat /tmp/sysinfo/model 2>/dev/null")
    if model == "" then model = helpers.exec("uci get system.@system[0].model 2>/dev/null") end
    if model == "" then model = "Generic OpenWrt Hardware" end
    
    return string.format(
        "%s\n" ..
        "*Hardware:* `%s`\n\n" ..
        "%s`%s`\n" ..
        "%s`%s`\n" ..
        "%s`%s`\n" ..
        "%s`%s`\n" ..
        "%s`%s`\n" ..
        "%s`%s`",
        lang.get("sys_title"), model,
        lang.get("sys_load"), cpu_load,
        lang.get("sys_ram"), ram_usage,
        lang.get("sys_flash"), flash_usage,
        lang.get("sys_temp"), cpu_temp,
        lang.get("sys_uptime"), uptime
    )
end

function M.execute_reboot()
    helpers.exec("sleep 1 && reboot &")
    return true
end

function M.execute_shutdown()
    helpers.exec("sleep 1 && poweroff &")
    return true
end

return M