-- core/logger.lua
-- Leveled file logger with simple size-based rotation, so a long-running
-- daemon on a router's small flash/overlay never grows an unbounded log.

local helpers = require("core.helpers")

local M = {
    path = "/var/log/owrt-tg-bot.log",
    max_size_kb = 256,
    level = "info",
}

local LEVELS = { debug = 1, info = 2, warn = 3, error = 4 }

function M.init(cfg)
    cfg = cfg or {}
    if cfg.logging then
        M.max_size_kb = tonumber(cfg.logging.max_size_kb) or M.max_size_kb
        M.level = cfg.logging.level or M.level
    end
end

local function rotate_if_needed()
    local f = io.open(M.path, "r")
    if not f then return end
    local size = f:seek("end")
    f:close()
    if size and size > (M.max_size_kb * 1024) then
        os.remove(M.path .. ".1")
        os.rename(M.path, M.path .. ".1")
    end
end

local function should_log(level)
    local want = LEVELS[M.level] or LEVELS.info
    local this = LEVELS[level] or LEVELS.info
    return this >= want
end

function M.log(level, msg)
    if not should_log(level) then return end
    rotate_if_needed()
    local line = string.format("[%s] [%s] %s\n", helpers.now(), level:upper(), msg)
    helpers.write_file(M.path, line, "a")
end

function M.debug(msg) M.log("debug", msg) end
function M.info(msg) M.log("info", msg) end
function M.warn(msg) M.log("warn", msg) end
function M.error(msg) M.log("error", msg) end

-- Return the last `n` lines of the log (used by the /logs command).
function M.tail(n)
    n = n or 30
    local content = helpers.read_file(M.path) or ""
    local lines = {}
    for line in content:gmatch("[^\r\n]+") do
        lines[#lines + 1] = line
    end
    local start = math.max(1, #lines - n + 1)
    local out = {}
    for i = start, #lines do
        out[#out + 1] = lines[i]
    end
    if #out == 0 then return "(log is empty)" end
    return table.concat(out, "\n")
end

return M
