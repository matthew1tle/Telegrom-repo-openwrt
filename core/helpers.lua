-- OpenWrt Telegram Bot Panel - Global System Helper Matrix
-- Production Ready, Safe Executions, JSON Parsing wrappers

local M = {}

local cjson = require("cjson")
local uci = require("uci")
local ubus = require("ubus")

-- File operations helpers
function M.read_file(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*all")
    f:close()
    -- Trim whitespace
    return content:gsub("^%s*(.-)%s*$", "%1")
end

function M.write_file(path, content)
    local f = io.open(path, "w")
    if not f then return false end
    f:write(content)
    f:close()
    return true
end

-- INI/Config parser specifically optimized for config.conf structure
function M.parse_config(path)
    local config = {}
    local current_section = nil
    
    local f = io.open(path, "r")
    if not f then return config end
    
    for line in f:lines() do
        line = line:gsub("^%s*(.-)%s*$", "%1") -- trim
        if line ~= "" and not line:match("^#") and not line:match("^;") then
            local section = line:match("^%[(.-)%]")
            if section then
                current_section = section
                config[current_section] = config[current_section] or {}
            elseif current_section and line:match("=") then
                local key, val = line:match("^([^=]+)=(.*)$")
                if key and val then
                    key = key:gsub("^%s*(.-)%s*$", "%1")
                    val = val:gsub("^%s*(.-)%s*$", "%1")
                    -- Strip quotes
                    val = val:gsub("^\"(.-)\"$", "%1")
                    config[current_section][key] = val
                end
            end
        end
    end
    f:close()
    return config
end

-- Safe execution mapping via io.popen
function M.exec(cmd)
    local f = io.popen(cmd .. " 2>/dev/null")
    if not f then return "" end
    local res = f:read("*all")
    f:close()
    return res:gsub("^%s*(.-)%s*$", "%1")
end

-- UCI Interface Abstraction Layer
function M.get_uci_val(package, section, option, default)
    local cursor = uci.cursor()
    local val = cursor:get(package, section, option)
    if val == nil then return default end
    return val
end

function M.set_uci_val(package, section, option, value)
    local cursor = uci.cursor()
    local ok = cursor:set(package, section, option, value)
    if ok then cursor:commit(package) end
    return ok
end

-- UBUS Request Bus Implementation
function M.ubus_call(object, method, params)
    local conn = ubus.connect()
    if not conn then return nil end
    local res = conn:call(object, method, params or {})
    conn:close()
    return res
end

-- Safe JSON encoders/decoders
function M.json_encode(data)
    local status, res = pcall(cjson.encode, data)
    if status then return res end
    return "{}"
end

function M.json_decode(str)
    if not str or str == "" then return {} end
    local status, res = pcall(cjson.decode, str)
    if status then return res end
    return {}
end

-- String formatting for raw byte sizes
function M.format_bytes(bytes)
    bytes = tonumber(bytes) or 0
    if bytes >= 1073741824 then
        return string.format("%.2f GB", bytes / 1073741824)
    elseif bytes >= 1048576 then
        return string.format("%.2f MB", bytes / 1048576)
    elseif bytes >= 1024 then
        return string.format("%.2f KB", bytes / 1024)
    else
        return bytes .. " B"
    end
end

return M