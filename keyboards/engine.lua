-- keyboards/engine.lua
-- Builds Telegram inline_keyboard structures. Every label goes through
-- i18n.t() instead of being hardcoded here, so the keyboards translate
-- automatically for whatever language is active - no per-menu language
-- branching needed. Emoji are part of the translated strings themselves
-- (see lang/*.lua) except for a few universal status marks (✅/❌) that
-- aren't really "text" so much as formatting.

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

function M.network_menu()
    return {
        inline_keyboard = {
            M.row(btn(i18n.t("btn_refresh"), "menu:network")),
            M.row(btn(i18n.t("btn_speedtest"), "network:speedtest")),
            M.row(btn(i18n.t("btn_back"), "menu:main")),
        },
    }
end

-- Tapping a client opens the detail/duration view instead of kicking
-- immediately - clients:show:<mac>.
function M.clients_list(clients)
    local rows = {}
    for _, c in ipairs(clients) do
        rows[#rows + 1] = M.row(btn(c.name, "clients:show:" .. c.mac))
    end
    rows[#rows + 1] = M.row(btn(i18n.t("btn_refresh"), "menu:clients"))
    rows[#rows + 1] = M.row(btn(i18n.t("btn_back"), "menu:main"))
    return { inline_keyboard = rows }
end

-- Duration picker + unblock, shown after tapping one client.
function M.client_detail(mac, currently_blocked)
    local rows = {
        M.row(
            btn(i18n.t("btn_block_5"), "clients:dur:" .. mac .. ":5"),
            btn(i18n.t("btn_block_30"), "clients:dur:" .. mac .. ":30")
        ),
        M.row(btn(i18n.t("btn_block_60"), "clients:dur:" .. mac .. ":60")),
    }
    if currently_blocked then
        rows[#rows + 1] = M.row(btn(i18n.t("btn_unblock"), "clients:unblock:" .. mac))
    end
    rows[#rows + 1] = M.row(btn(i18n.t("btn_back"), "menu:clients"))
    return { inline_keyboard = rows }
end

-- Tapping a radio opens the detail view - wifi:show:<section>.
function M.wifi_list(radios)
    local rows = {}
    for _, r in ipairs(radios) do
        local mark = r.disabled and "🔴" or "🟢"
        rows[#rows + 1] = M.row(btn(mark .. " " .. r.name, "wifi:show:" .. r.section))
    end
    rows[#rows + 1] = M.row(btn(i18n.t("btn_back"), "menu:main"))
    return { inline_keyboard = rows }
end

-- Toggle / rename / change password, shown after tapping one radio.
function M.wifi_detail(radio)
    local toggle_label = radio.disabled and i18n.t("btn_wifi_turn_on") or i18n.t("btn_wifi_turn_off")
    return {
        inline_keyboard = {
            M.row(btn(toggle_label, "wifi:toggle:" .. radio.section)),
            M.row(btn(i18n.t("btn_wifi_rename"), "wifi:rename:" .. radio.section)),
            M.row(btn(i18n.t("btn_wifi_password"), "wifi:pass:" .. radio.section)),
            M.row(btn(i18n.t("btn_back"), "menu:wifi")),
        },
    }
end

-- Shown while the bot is waiting for a typed reply (new SSID/password) -
-- lets the user back out without typing anything.
function M.cancel_only(cancel_callback)
    return {
        inline_keyboard = {
            M.row(btn(i18n.t("btn_cancel"), cancel_callback)),
        },
    }
end

function M.packages_menu()
    return {
        inline_keyboard = {
            M.row(btn(i18n.t("btn_refresh"), "menu:packages")),
            M.row(btn(i18n.t("btn_packages_list"), "packages:list")),
            M.row(btn(i18n.t("btn_back"), "menu:main")),
        },
    }
end

function M.backup_menu()
    return {
        inline_keyboard = {
            M.row(btn(i18n.t("btn_backup_create"), "backup:create")),
            M.row(btn(i18n.t("btn_backup_restore"), "backup:restore")),
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
