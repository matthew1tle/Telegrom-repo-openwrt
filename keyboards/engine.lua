-- keyboards/engine.lua
-- Builds Telegram inline_keyboard structures. Every label goes through
-- i18n.t() instead of being hardcoded here, so the keyboards translate
-- automatically for whatever language is active - no per-menu language
-- branching needed.

local i18n = require("core.i18n")

local M = {}

local function btn(text, callback_data)
    return { text = text, callback_data = callback_data }
end

function M.row(...)
    return { ... }
end

function M.main_menu()
    return {
        inline_keyboard = {
            M.row(btn(i18n.t("btn_system"), "menu:system"), btn(i18n.t("btn_network"), "menu:network")),
            M.row(btn(i18n.t("btn_clients"), "menu:clients"), btn(i18n.t("btn_wifi"), "menu:wifi")),
            M.row(btn(i18n.t("btn_packages"), "menu:packages"), btn(i18n.t("btn_backup"), "menu:backup")),
            M.row(btn(i18n.t("btn_logs"), "menu:logs"), btn(i18n.t("btn_language"), "menu:language")),
        },
    }
end

function M.back_only()
    return {
        inline_keyboard = {
            M.row(btn(i18n.t("btn_back"), "menu:main")),
        },
    }
end

function M.with_refresh(refresh_callback)
    return {
        inline_keyboard = {
            M.row(btn(i18n.t("btn_refresh"), refresh_callback)),
            M.row(btn(i18n.t("btn_back"), "menu:main")),
        },
    }
end

function M.clients_list(clients)
    local rows = {}
    for _, c in ipairs(clients) do
        rows[#rows + 1] = M.row(btn("⛔ " .. c.name, "clients:kick:" .. c.mac))
    end
    rows[#rows + 1] = M.row(btn(i18n.t("btn_refresh"), "menu:clients"))
    rows[#rows + 1] = M.row(btn(i18n.t("btn_back"), "menu:main"))
    return { inline_keyboard = rows }
end

function M.wifi_list(radios)
    local rows = {}
    for _, r in ipairs(radios) do
        local label = (r.disabled and "🔴 " or "🟢 ") .. r.name
        rows[#rows + 1] = M.row(btn(label, "wifi:toggle:" .. r.name))
    end
    rows[#rows + 1] = M.row(btn(i18n.t("btn_back"), "menu:main"))
    return { inline_keyboard = rows }
end

function M.backup_menu()
    return {
        inline_keyboard = {
            M.row(btn("💾 " .. i18n.t("btn_backup"), "backup:create")),
            M.row(btn("♻️ Restore", "backup:restore")),
            M.row(btn(i18n.t("btn_back"), "menu:main")),
        },
    }
end

-- Language menu is generated from whatever files exist in lang/, so
-- dropping in a new translation makes it selectable automatically.
function M.language_menu(available_codes, names)
    local rows = {}
    for _, code in ipairs(available_codes) do
        rows[#rows + 1] = M.row(btn(names[code] or code, "lang:set:" .. code))
    end
    rows[#rows + 1] = M.row(btn(i18n.t("btn_back"), "menu:main"))
    return { inline_keyboard = rows }
end

return M
