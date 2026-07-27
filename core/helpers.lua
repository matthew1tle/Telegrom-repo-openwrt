-- core/helpers.lua
-- Small utility layer shared by every module: shell execution, the custom
-- INI-style config parser, JSON encode/decode wrappers and string helpers.
-- Kept dependency-free (besides lua-cjson) so it runs on the stock OpenWrt
-- Lua runtime with no extra rocks/modules.

local ok_cjson, cjson = pcall(require, "cjson")
if not ok_cjson then
    cjson = pcall(require, "cjson.safe") and require("cjson.safe") or nil
end

local M = {}

function M.trim(s)
    if not s then return "" end
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Run a shell command and return (stdout, ok, exit_code)
function M.shell(cmd)
    local handle = io.popen(cmd .. " 2>/dev/null")
    if not handle then return "", false, -1 end
    local out = handle:read("*a") or ""
    local ok, _, code = handle:close()
    return out, ok and true or false, code or 0
end

function M.read_file(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    return content
end

function M.write_file(path, content, mode)
    local f = io.open(path, mode or "w")
    if not f then return false end
    f:write(content)
    f:close()
    return true
end

function M.file_exists(path)
    local f = io.open(path, "r")
    if f then f:close(); return true end
    return false
end

-- JSON --------------------------------------------------------------------

function M.json_encode(tbl)
    if not cjson then return nil, "lua-cjson not available" end
    local ok, res = pcall(cjson.encode, tbl)
    if not ok then return nil, res end
    return res
end

function M.json_decode(str)
    if not cjson then return nil, "lua-cjson not available" end
    if not str or str == "" then return nil, "empty body" end
    local ok, res = pcall(cjson.decode, str)
    if not ok then return nil, res end
    return res
end

-- INI-style config parser ---------------------------------------------------
-- Parses files shaped like:
--   [section]
--   key="value"
--   key=value
-- Returns a nested table: cfg.section.key = "value"

function M.parse_conf(path)
    local content = M.read_file(path)
    if not content then return nil, "cannot read " .. tostring(path) end

    local cfg = {}
    local section = nil

    for line in content:gmatch("[^\r\n]+") do
        local trimmed = M.trim(line)
        if trimmed ~= "" and trimmed:sub(1, 1) ~= ";" and trimmed:sub(1, 1) ~= "#" then
            local sec = trimmed:match("^%[([%w_.-]+)%]$")
            if sec then
                section = sec
                cfg[section] = cfg[section] or {}
            else
                local key, val = trimmed:match("^([%w_.-]+)%s*=%s*(.*)$")
                if key and section then
                    val = M.trim(val)
                    -- strip a single pair of matching quotes
                    val = val:gsub('^"(.*)"$', "%1")
                    val = val:gsub("^'(.*)'$", "%1")
                    cfg[section][key] = val
                end
            end
        end
    end

    return cfg
end

-- Split a comma-separated list into a trimmed array, e.g. allowed_chat_ids
function M.split_list(str)
    local out = {}
    if not str then return out end
    for item in str:gmatch("[^,]+") do
        local trimmed = M.trim(item)
        if trimmed ~= "" then out[#out + 1] = trimmed end
    end
    return out
end

function M.in_list(list, value)
    for _, v in ipairs(list) do
        if tostring(v) == tostring(value) then return true end
    end
    return false
end

-- Shell-quote a string for safe use as a single argument in sh. Anything
-- coming from uci output (like @wifi-iface[0]) or a MAC address must go
-- through this before it's interpolated into a shell command - unquoted,
-- "[0]" is a glob character class to the shell and silently breaks the
-- command instead of raising a visible error.
function M.shq(s)
    return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

function M.shell_exists(bin)
    local _, ok = M.shell("command -v " .. M.shq(bin))
    return ok
end

function M.now()
    return os.date("%Y-%m-%d %H:%M:%S")
end

return M
