-- modules/package.lua
-- Wraps whichever package manager the firmware uses (apk on 24.x+, opkg on
-- 23.x and older) behind one interface.

local helpers = require("core.helpers")
local i18n = require("core.i18n")

local M = {}

local function manager()
    local _, has_apk = helpers.shell("command -v apk")
    if has_apk then return "apk" end
    return "opkg"
end

function M.installed_count()
    local mgr = manager()
    local out
    if mgr == "apk" then
        out = helpers.shell("apk list --installed 2>/dev/null | wc -l")
    else
        out = helpers.shell("opkg list-installed 2>/dev/null | wc -l")
    end
    return tonumber(helpers.trim(out)) or 0
end

function M.upgradable_count()
    local mgr = manager()
    local out
    if mgr == "apk" then
        helpers.shell("apk update 2>/dev/null")
        out = helpers.shell("apk list --upgradable 2>/dev/null | wc -l")
    else
        helpers.shell("opkg update 2>/dev/null")
        out = helpers.shell("opkg list-upgradable 2>/dev/null | wc -l")
    end
    return tonumber(helpers.trim(out)) or 0
end

-- Names (and, where the tool reports it, old/new versions) of every
-- package with an update available - sent as its own plain-text message
-- rather than folded into the summary view, since it can run long.
function M.upgradable_list()
    local mgr = manager()
    local out
    if mgr == "apk" then
        out = helpers.shell("apk list --upgradable 2>/dev/null")
    else
        out = helpers.shell("opkg list-upgradable 2>/dev/null")
    end
    local names = {}
    for line in out:gmatch("[^\r\n]+") do
        local name = line:match("^(%S+)")
        if name then names[#names + 1] = name end
    end
    return names
end

function M.render()
    local count = M.installed_count()
    local upgradable = M.upgradable_count()

    local lines = {
        "<b>" .. i18n.t("packages_title") .. "</b>",
        "",
        i18n.t("packages_installed_count", { count = count }),
        upgradable > 0
            and i18n.t("packages_upgrade_available", { count = upgradable })
            or i18n.t("packages_up_to_date"),
    }
    return table.concat(lines, "\n")
end

return M
