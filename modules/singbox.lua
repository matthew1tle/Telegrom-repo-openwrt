-- modules/singbox.lua
-- Status / toggle wrapper for the sing-box service, if installed.

local helpers = require("core.helpers")
local i18n = require("core.i18n")

local M = {}

function M.is_installed()
    return helpers.file_exists("/etc/init.d/sing-box")
end

function M.status()
    if not M.is_installed() then return "not installed" end
    local _, running = helpers.shell("/etc/init.d/sing-box status >/dev/null 2>&1")
    return running and "running" or "stopped"
end

function M.toggle()
    if not M.is_installed() then return false end
    local status = M.status()
    if status == "running" then
        helpers.shell("/etc/init.d/sing-box stop")
    else
        helpers.shell("/etc/init.d/sing-box start")
    end
    return true
end

function M.render()
    if not M.is_installed() then
        return i18n.t("singbox_status", { status = "not installed" })
    end
    return i18n.t("singbox_status", { status = M.status() })
end

return M
