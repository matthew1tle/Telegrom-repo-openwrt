-- OpenWrt Telegram Bot Panel - Production Syslog & File Logging Engine
-- Supports standard Syslog Levels

local helpers = require("core.helpers")

local M = {}

M.levels = {
    EMERG   = 0,
    ALERT   = 1,
    CRIT    = 2,
    ERR     = 3,
    WARN    = 4,
    NOTICE  = 5,
    INFO    = 6,
    DEBUG   = 7
}

local current_level = 6
local log_file_path = "/var/log/owrt-tg-bot.log"

function M.init(level, path)
    if level then current_level = tonumber(level) or 6 end
    if path then log_file_path = path end
end

local function write_log(level_name, level_val, message)
    if level_val > current_level then return end
    
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local format_msg = string.format("[%s] [%s] %s\n", timestamp, level_name, message)
    
    -- Append to runtime log file
    local f = io.open(log_file_path, "a")
    if f then
        f:write(format_msg)
        f:close()
    end
    
    -- Output directly to stdout for systemd/procd capture logging
    print(format_msg:gsub("\n$", ""))
end

function M.emerg(msg)  write_log("EMERG",  M.levels.EMERG,  msg) end
function M.alert(msg)  write_log("ALERT",  M.levels.ALERT,  msg) end
function M.crit(msg)   write_log("CRIT",   M.levels.CRIT,   msg) end
function M.err(msg)    write_log("ERR",    M.levels.ERR,    msg) end
function M.warn(msg)   write_log("WARN",   M.levels.WARN,   msg) end
function M.notice(msg) write_log("NOTICE", M.levels.NOTICE, msg) end
function M.info(msg)   write_log("INFO",   M.levels.INFO,   msg) end
function M.debug(msg)  write_log("DEBUG",  M.levels.DEBUG,  msg) end

return M