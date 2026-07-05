-- OpenWrt Telegram Bot Panel - System Resource Telemetry Module
local helpers = require("core.helpers")
local M = {}

function M.get_cpu_load()
    local load = helpers.exec("cat /proc/loadavg")
    if load and load ~= "" then
        local lav1, lav5, lav15 = load:match("^([^%s]+)%s+([^%s]+)%s+([^%s]+)")
        if lav1 then
            return string.format("%s, %s, %s", lav1, lav5, lav15)
        end
    end
    return "0.00, 0.00, 0.00"
end

function M.get_ram_usage()
    local meminfo = helpers.exec("cat /proc/meminfo")
    if not meminfo or meminfo == "" then return "Data Unavailable" end
    
    local mem_total = tonumber(meminfo:match("MemTotal:%s+(%d+)")) or 0
    local mem_free = tonumber(meminfo:match("MemFree:%s+(%d+)")) or 0
    local mem_cached = tonumber(meminfo:match("Cached:%s+(%d+)")) or 0
    local mem_buffers = tonumber(meminfo:match("Buffers:%s+(%d+)")) or 0
    
    if mem_total > 0 then
        local mem_used = mem_total - (mem_free + mem_cached + mem_buffers)
        local pct = (mem_used / mem_total) * 100
        return string.format("%.1f%% (%s / %s)", pct, helpers.format_bytes(mem_used * 1024), helpers.format_bytes(mem_total * 1024))
    end
    return "Data Unavailable"
end

function M.get_cpu_temp()
    local paths = {
        "/sys/class/thermal/thermal_zone0/temp",
        "/sys/class/thermal/thermal_zone1/temp",
        "/sys/class/hwmon/hwmon0/temp1_input",
        "/sys/class/hwmon/hwmon0/device/temp1_input"
    }
    
    for _, path in ipairs(paths) do
        local raw = helpers.exec(string.format("cat %s 2>/dev/null", path))
        if raw and raw ~= "" then
            local temp = raw:match("(%d+)")
            if temp then
                local t = tonumber(temp)
                if t > 1000 then t = t / 1000 end
                if t > 0 and t < 120 then
                    return string.format("%.1f°C", t)
                end
            end
        end
    end
    return "N/A"
end

function M.get_flash_usage()
    local df = helpers.exec("df -k /")
    if df and df ~= "" then
        local pct_str = df:match("(%d+)%%%s+/[%s%c]*$") or df:match("(%d+)%%")
        if pct_str then
            return pct_str .. "% Allocated"
        end
    end
    return "Data Unavailable"
end

function M.get_system_uptime()
    local uptime_raw = helpers.exec("cat /proc/uptime")
    if uptime_raw and uptime_raw ~= "" then
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
    return "Unknown Uptime"
end

function M.get_metrics_summary()
    local cpu_load = M.get_cpu_load()
    local ram_usage = M.get_ram_usage()
    local flash_usage = M.get_flash_usage()
    local cpu_temp = M.get_cpu_temp()
    local uptime = M.get_system_uptime()
    
    local model = helpers.exec("cat /tmp/sysinfo/model 2>/dev/null")
    if not model or model == "" then model = helpers.exec("uci get system.@system[0].model 2>/dev/null") end
    if not model or model == "" then model = "Google WiFi (Gale)" end
    
    model = model:gsub("^%s*(.-)%s*$", "%1")
    
    -- Safe sequential concatenation assembly layout bypasses string parsing rules completely
    local output = "💻 *System Hardware Parameters*\n" ..
                   "*Hardware:* `" .. model .. "`\n\n" ..
                   "*Load Average:* `" .. cpu_load .. "`\n" ..
                   "*Memory Usage:* `" .. ram_usage .. "`\n" ..
                   "*Storage Partition:* `" .. flash_usage .. "`\n" ..
                   "*Core Temp:* `" .. cpu_temp .. "`\n" ..
                   "*Uptime:* `" .. uptime .. "`"
                   
    return output
end

return M