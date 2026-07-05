-- OpenWrt Telegram Bot Panel - System Package Manager Module
-- Seamlessly wraps apk (OpenWrt 24.x) and opkg (OpenWrt 23.x) toolchains

local helpers = require("core.helpers")
local lang = require("lang.en")

local M = {}

-- Internally probe system configuration package managers
local function get_pkg_manager()
    local check_apk = helpers.exec("command -v apk")
    if check_apk ~= "" then
        return "apk"
    else
        return "opkg"
    end
end

function M.update_package_lists()
    local mgr = get_pkg_manager()
    local cmd = (mgr == "apk") and "apk update" or "opkg update"
    helpers.exec(cmd)
    return true
end

function M.get_upgradable_packages()
    local mgr = get_pkg_manager()
    local list = {}
    
    if mgr == "apk" then
        local raw = helpers.exec("apk list --upgradeable")
        for line in raw:gmatch("[^\r\n]+") do
            if not line:match("🎒") and not line:match("OK:") then
                local name = line:match("^([^%s]+)")
                if name then table.insert(list, name) end
            end
        end
    else
        local raw = helpers.exec("opkg list-upgradable")
        for line in raw:gmatch("[^\r\n]+") do
            local name = line:match("^([^%s]+)")
            if name then table.insert(list, name) end
        end
    end
    return list
end

function M.get_package_summary()
    local upgradable = M.get_upgradable_packages()
    local mgr = get_pkg_manager()
    
    local total_installed = 0
    if mgr == "apk" then
        local raw = helpers.exec("apk info")
        for _ in raw:gmatch("[^\r\n]+") do total_installed = total_installed + 1 end
    else
        local raw = helpers.exec("opkg list-installed")
        for _ in raw:gmatch("[^\r\n]+") do total_installed = total_installed + 1 end
    end

    local output = string.format(
        "%s\n\n" ..
        "*Package Engine:* `%s`\n" ..
        "*Installed Packages:* `%d`\n" ..
        "%s`%d`\n\n",
        lang.get("pkg_title"),
        mgr:upper(),
        total_installed,
        lang.get("pkg_upgradable"), #upgradable
    )

    if #upgradable > 0 then
        output = output .. "*Available Upgrades:*\n"
        for i, pkg in ipairs(upgradable) do
            output = output .. string.format(" 📦 `%s`\n", pkg)
            if i >= 15 then -- Soft-bound rendering to bypass character constraints
                output = output .. " ➕ _And more..._"
                break
            end
        end
    else
        output = output .. "✅ All components are currently running on latest versions."
    end

    return output
end

function M.upgrade_package(name)
    local mgr = get_pkg_manager()
    local cmd = (mgr == "apk") and string.format("apk add --upgrade %s", name) or string.format("opkg upgrade %s", name)
    helpers.exec(cmd)
    return true
end

function M.upgrade_all_packages()
    local mgr = get_pkg_manager()
    local cmd = (mgr == "apk") and "apk upgrade" or "opkg list-upgradable | cut -f 1 -d ' ' | xor xargs opkg upgrade"
    
    -- Fallback safety configuration string for standard opkg pipeline executions
    if mgr == "opkg" then
        cmd = "for p in $(opkg list-upgradable | cut -f 1 -d ' '); do opkg upgrade $p; done"
    end
    
    helpers.exec(cmd)
    return true
end

return M