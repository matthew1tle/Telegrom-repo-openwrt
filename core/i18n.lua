-- core/i18n.lua
--
-- Every other file in this project (router, keyboards, modules, alerts)
-- pulls its text through i18n.t("some_key") instead of holding strings of
-- its own. That means adding a new language is a two-step, one-file job:
--
--   1. Copy lang/en.lua to lang/<code>.lua and translate the values.
--   2. Set language="<code>" in config.conf's [general] section.
--
-- No other file needs to change. Missing keys in a translation silently
-- fall back to the English string, so a half-finished translation never
-- breaks the bot - it just shows English for whatever isn't done yet.

local helpers = require("core.helpers")

local M = {
    code = "en",
    strings = {},
    base = {},
}

-- IMPORTANT: this must NOT be a bare relative path like "lang". procd
-- starts main.lua with the working directory at "/", not at the install
-- directory, so a relative path here silently fails to find any lang
-- file, every string falls back to a two-key emergency stub, and every
-- button/label ends up showing its raw key (e.g. "btn_wifi") instead of
-- translated text. Resolve lang/ relative to where THIS file physically
-- lives instead, so it works no matter what the process's cwd is.
local function installed_dir()
    local info = debug.getinfo(1, "S")
    local source = info.source:match("^@(.+)$") or info.source
    local dir = source:match("^(.*)[/\\][^/\\]+$")
    return dir and (dir .. "/..") or "."
end

local LANG_DIR = installed_dir() .. "/lang"

local function load_lang_file(code)
    local path = string.format("%s/%s.lua", LANG_DIR, code)
    if not helpers.file_exists(path) then return nil end
    local chunk, err = loadfile(path)
    if not chunk then return nil, err end
    local ok, tbl = pcall(chunk)
    if not ok or type(tbl) ~= "table" then return nil, "malformed language file: " .. code end
    return tbl
end

-- List every language code available on disk, by scanning lang/*.lua
function M.available()
    local out = {}
    local listing = helpers.shell("ls " .. LANG_DIR .. " 2>/dev/null")
    for filename in listing:gmatch("[^\r\n]+") do
        local code = filename:match("^(.-)%.lua$")
        if code then out[#out + 1] = code end
    end
    return out
end

-- Load `code`, falling back to English for anything missing, and falling
-- back to a hardcoded stub if even English fails to load (should never
-- happen, but a bot with no strings at all is worse than one with terse
-- English placeholders).
function M.load(code)
    code = code or "en"

    M.base = load_lang_file("en") or {
        access_denied = "Access denied.",
        error_generic = "Something went wrong.",
    }

    local chosen = load_lang_file(code)
    if not chosen then
        chosen = {}
    end

    M.strings = setmetatable({}, {
        __index = function(_, key)
            return chosen[key] or M.base[key]
        end,
    })

    M.code = code
    return M.strings
end

-- i18n.t("key", {name = "eth0"}) -> string with %{name} substitutions.
-- Falls back to the raw key itself if it's missing from every language,
-- so a bug shows up as a visible placeholder instead of a Lua error.
function M.t(key, vars)
    local template = M.strings[key]
    if not template then return key end
    if not vars then return template end
    return (template:gsub("%%{(%w+)}", function(name)
        return tostring(vars[name] or "")
    end))
end

return M
