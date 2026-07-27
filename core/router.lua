-- core/router.lua
-- Every incoming update passes through here first for auth, then gets
-- dispatched by command / callback_data prefix to the module that owns it.
--
-- Design note on message clutter: earlier versions sent a fresh
-- sendMessage() for every confirmation ("Wi-Fi toggled", "client kicked",
-- "backup starting"...) on top of the menu message that was already being
-- edited in place. That left two things drifting out of sync in the chat
-- history and made the menu hard to keep using. Now, confirmations for
-- button presses go out as a small callback-query popup (answerCallbackQuery
-- text), and the one menu message just gets edited in place - so the chat
-- stays to a single evolving screen instead of a growing stack of messages.

local helpers = require("core.helpers")
local logger = require("core.logger")
local telegram = require("core.telegram")
local state = require("core.state")
local i18n = require("core.i18n")
local keyboards = require("keyboards.engine")

local system = require("modules.system")
local monitor = require("modules.monitor")
local internet = require("modules.internet")
local clients = require("modules.clients")
local wifi = require("modules.wifi")
local pkg = require("modules.package")
local backup = require("modules.backup")

local M = {
    allowed_chat_ids = {},
}

local LANGUAGE_NAMES = {
    en = "English",
    fa = "فارسی",
}

function M.init(cfg)
    M.allowed_chat_ids = helpers.split_list(cfg.telegram and cfg.telegram.allowed_chat_ids)
end

local function is_authorized(chat_id)
    return helpers.in_list(M.allowed_chat_ids, chat_id)
end

local function send_main_menu(chat_id)
    local result = telegram.send_message(chat_id, "<b>" .. i18n.t("welcome") .. "</b>", keyboards.main_menu())
    if result and result.message_id then
        state.set_menu_message(chat_id, result.message_id)
    end
end

local function wifi_detail_text(radio)
    return i18n.t("wifi_detail_header", { name = radio.name }) .. "\n\n"
        .. i18n.t(radio.disabled and "wifi_disabled" or "wifi_enabled", { name = radio.name })
end

local function client_detail_text(client, blocked)
    return "<b>" .. client.name .. "</b> (" .. client.ip .. ")\n\n"
        .. i18n.t(blocked and "clients_detail_status_blocked" or "clients_detail_status_ok", { name = client.name })
end

-- ---------------------------------------------------------------- commands

-- Only /start is a typed command. Every other action (system, network,
-- clients, wifi, packages, backup/restore, logs, language) is reachable
-- exclusively through the inline keyboard buttons - any other typed text
-- either completes a pending prompt (new SSID/password) or just points
-- back at the menu.
local function handle_command(chat_id, text)
    local cmd = text:match("^(/%S+)")
    if cmd == "/start" then
        state.clear(chat_id)
        send_main_menu(chat_id)
    else
        telegram.send_message(chat_id, i18n.t("unknown_command"))
        send_main_menu(chat_id)
    end
end

-- --------------------------------------------------------- text replies

-- Handles a typed reply while state.awaiting is set (new SSID / new Wi-Fi
-- password). Returns true if the text was consumed this way.
local function handle_awaited_text(chat_id, text)
    local awaiting = state.awaiting(chat_id)
    if not awaiting then return false end

    local kind, section = awaiting:match("^([%w_]+):(.+)$")
    if not kind then return false end

    local menu_id = state.get_menu_message(chat_id)

    if kind == "wifi_ssid" then
        state.set_awaiting(chat_id, nil)
        local ok = wifi.set_ssid(section, text)
        local radio = wifi.get(section)
        if ok then
            if menu_id then
                telegram.edit_message(chat_id, menu_id,
                    wifi_detail_text(radio) .. "\n\n" .. i18n.t("wifi_ssid_updated"),
                    keyboards.wifi_detail(radio))
            end
        else
            state.set_awaiting(chat_id, "wifi_ssid:" .. section)
            if menu_id then
                telegram.edit_message(chat_id, menu_id, i18n.t("wifi_ssid_invalid"),
                    keyboards.cancel_only("wifi:show:" .. section))
            end
        end
        return true
    elseif kind == "wifi_pass" then
        state.set_awaiting(chat_id, nil)
        local ok = wifi.set_password(section, text)
        local radio = wifi.get(section)
        if ok then
            if menu_id then
                telegram.edit_message(chat_id, menu_id,
                    wifi_detail_text(radio) .. "\n\n" .. i18n.t("wifi_password_updated"),
                    keyboards.wifi_detail(radio))
            end
        else
            state.set_awaiting(chat_id, "wifi_pass:" .. section)
            if menu_id then
                telegram.edit_message(chat_id, menu_id, i18n.t("wifi_password_invalid"),
                    keyboards.cancel_only("wifi:show:" .. section))
            end
        end
        return true
    end

    return false
end

-- ------------------------------------------------------------- callbacks

local function handle_menu(chat_id, message_id, target)
    if target == "main" then
        state.clear(chat_id)
        state.set_menu_message(chat_id, message_id)
        telegram.edit_message(chat_id, message_id, "<b>" .. i18n.t("welcome") .. "</b>", keyboards.main_menu())
    elseif target == "system" then
        telegram.edit_message(chat_id, message_id, system.render(), keyboards.with_refresh("menu:system"))
    elseif target == "network" then
        local text = monitor.render() .. "\n\n" .. internet.render()
        telegram.edit_message(chat_id, message_id, text, keyboards.network_menu())
    elseif target == "clients" then
        local text, list = clients.render()
        telegram.edit_message(chat_id, message_id, text, keyboards.clients_list(list))
    elseif target == "wifi" then
        local text, radios = wifi.render()
        telegram.edit_message(chat_id, message_id, text, keyboards.wifi_list(radios))
    elseif target == "packages" then
        telegram.edit_message(chat_id, message_id, pkg.render(), keyboards.packages_menu())
    elseif target == "backup" then
        telegram.edit_message(chat_id, message_id, "<b>" .. i18n.t("backup_title") .. "</b>", keyboards.backup_menu())
    elseif target == "logs" then
        local logger_mod = require("core.logger")
        local text = "<b>" .. i18n.t("logs_title") .. "</b>\n<pre>" .. logger_mod.tail(30) .. "</pre>"
        telegram.edit_message(chat_id, message_id, text, keyboards.with_refresh("menu:logs"))
    elseif target == "language" then
        telegram.edit_message(chat_id, message_id, "<b>" .. i18n.t("language_title") .. "</b>",
            keyboards.language_menu(i18n.available(), LANGUAGE_NAMES))
    end
end

-- Returns an optional short popup string to show via answerCallbackQuery.
local function handle_clients(chat_id, message_id, action, arg)
    if action == "show" then
        local mac = arg
        local blocked = clients.is_blocked(mac)
        local list = clients.list()
        local found = nil
        for _, c in ipairs(list) do
            if c.mac == mac then found = c end
        end
        found = found or { mac = mac, ip = "?", name = mac }
        telegram.edit_message(chat_id, message_id, client_detail_text(found, blocked),
            keyboards.client_detail(mac, blocked))
        return nil
    elseif action == "dur" then
        local mac, minutes = arg:match("^(.+):(%d+)$")
        minutes = tonumber(minutes)
        if not mac or not minutes then return nil end
        local ok = clients.block(mac, minutes)
        local list = clients.list()
        local found = nil
        for _, c in ipairs(list) do
            if c.mac == mac then found = c end
        end
        found = found or { mac = mac, ip = "?", name = mac }
        telegram.edit_message(chat_id, message_id, client_detail_text(found, true),
            keyboards.client_detail(mac, true))
        return ok and i18n.t("clients_block_done", { name = found.name, minutes = minutes })
            or i18n.t("clients_block_fail", { name = found.name })
    elseif action == "unblock" then
        local mac = arg
        clients.unblock(mac)
        local list = clients.list()
        local found = nil
        for _, c in ipairs(list) do
            if c.mac == mac then found = c end
        end
        found = found or { mac = mac, ip = "?", name = mac }
        telegram.edit_message(chat_id, message_id, client_detail_text(found, false),
            keyboards.client_detail(mac, false))
        return i18n.t("clients_unblock_done", { name = found.name })
    end
    return nil
end

local function handle_wifi(chat_id, message_id, action, section)
    if action == "show" then
        local radio = wifi.get(section)
        telegram.edit_message(chat_id, message_id, wifi_detail_text(radio), keyboards.wifi_detail(radio))
        return nil
    elseif action == "toggle" then
        local ok, is_now_disabled = wifi.toggle(section)
        local radio = wifi.get(section)
        telegram.edit_message(chat_id, message_id, wifi_detail_text(radio), keyboards.wifi_detail(radio))
        if not ok then return i18n.t("error_generic") end
        return i18n.t(is_now_disabled and "wifi_turned_off" or "wifi_turned_on", { name = radio.name })
    elseif action == "rename" then
        state.set_awaiting(chat_id, "wifi_ssid:" .. section)
        telegram.edit_message(chat_id, message_id, i18n.t("wifi_rename_prompt"),
            keyboards.cancel_only("wifi:show:" .. section))
        return nil
    elseif action == "pass" then
        state.set_awaiting(chat_id, "wifi_pass:" .. section)
        telegram.edit_message(chat_id, message_id, i18n.t("wifi_password_prompt"),
            keyboards.cancel_only("wifi:show:" .. section))
        return nil
    end
    return nil
end

-- Runs synchronously and can take several seconds (or longer for a real
-- speed test client) - the menu is updated to a "running" state first so
-- the wait isn't silent, then updated again with the result.
local function handle_network(chat_id, message_id, action)
    if action == "speedtest" then
        telegram.edit_message(chat_id, message_id, i18n.t("internet_speedtest_running"), keyboards.network_menu())
        local result_text = internet.speedtest_render()
        local text = monitor.render() .. "\n\n" .. internet.render() .. "\n\n" .. result_text
        telegram.edit_message(chat_id, message_id, text, keyboards.network_menu())
        return nil
    end
    return nil
end

local function handle_packages(chat_id, message_id, action)
    if action == "list" then
        local names = pkg.upgradable_list()
        local text
        if #names == 0 then
            text = i18n.t("packages_updates_list_empty")
        else
            local lines = { i18n.t("packages_updates_list_header"), "" }
            for _, name in ipairs(names) do
                lines[#lines + 1] = "• " .. name
            end
            text = table.concat(lines, "\n")
        end
        -- Sent as its own message (rather than editing the menu) since
        -- this list is the actual content being requested, not a status
        -- update to the menu view.
        telegram.send_message(chat_id, text)
        return nil
    end
    return nil
end

local function handle_backup(chat_id, message_id, action)
    if action == "create" then
        backup.create(chat_id)
        return i18n.t("backup_running")
    elseif action == "restore" then
        state.set_awaiting(chat_id, "restore_file")
        telegram.edit_message(chat_id, message_id, i18n.t("restore_prompt"), keyboards.cancel_only("menu:backup"))
        return nil
    end
    return nil
end

local function handle_language(chat_id, message_id, code)
    -- Switching languages only needs a config write + reload; every
    -- keyboard/module already reads through i18n.t(), so nothing else in
    -- the codebase needs to change for a new language to "just work".
    helpers.shell(
        "sed -i " .. helpers.shq('s/^language=.*/language="' .. code .. '"/')
        .. " /etc/owrt-tg-bot/config.conf"
    )
    i18n.load(code)
    telegram.edit_message(chat_id, message_id, "<b>" .. i18n.t("welcome") .. "</b>", keyboards.main_menu())
    return i18n.t("language_set", { name = LANGUAGE_NAMES[code] or code })
end

local function handle_callback(update)
    local cq = update.callback_query
    local chat_id = cq.message.chat.id
    local message_id = cq.message.message_id
    local data = cq.data or ""

    if not is_authorized(chat_id) then
        telegram.answer_callback(cq.id, i18n.t("access_denied"))
        logger.warn("unauthorized callback from chat " .. tostring(chat_id))
        return
    end

    state.set_menu_message(chat_id, message_id)
    -- Any button press cancels a pending typed-reply prompt (rename,
    -- password change, restore upload); the handler below may set a new
    -- one right back if that's what the button was for.
    state.set_awaiting(chat_id, nil)

    local kind, a, b = data:match("^(%w+):([%w_]+):?(.*)$")
    local popup = nil

    if kind == "menu" then
        handle_menu(chat_id, message_id, a)
    elseif kind == "clients" then
        popup = handle_clients(chat_id, message_id, a, b)
    elseif kind == "wifi" then
        popup = handle_wifi(chat_id, message_id, a, b)
    elseif kind == "network" then
        popup = handle_network(chat_id, message_id, a)
    elseif kind == "packages" then
        popup = handle_packages(chat_id, message_id, a)
    elseif kind == "backup" then
        popup = handle_backup(chat_id, message_id, a)
    elseif kind == "lang" and a == "set" then
        popup = handle_language(chat_id, message_id, b)
    end

    telegram.answer_callback(cq.id, popup)
end

-- --------------------------------------------------------------- messages

-- A file arriving while state.awaiting == "restore_file" is treated as a
-- restore upload rather than a normal chat message.
local function handle_document(chat_id, document)
    if state.awaiting(chat_id) ~= "restore_file" then return false end
    state.set_awaiting(chat_id, nil)
    local menu_id = state.get_menu_message(chat_id)

    local dest = "/tmp/owrt-tg-bot-restore.tar.gz"
    local ok, err = telegram.download_file(document.file_id, dest)
    local result_text
    if not ok then
        result_text = i18n.t("restore_failed", { reason = err or "download" })
    else
        local restored, reason = backup.restore(dest)
        if restored then
            result_text = i18n.t("restore_done")
        elseif reason == "not_a_backup" then
            result_text = i18n.t("restore_wrong_file")
        else
            result_text = i18n.t("restore_failed", { reason = reason or "unknown" })
        end
    end

    if menu_id then
        telegram.edit_message(chat_id, menu_id, result_text, keyboards.back_only())
    else
        telegram.send_message(chat_id, result_text)
    end
    return true
end

local function handle_message(update)
    local msg = update.message
    local chat_id = msg.chat.id

    if not is_authorized(chat_id) then
        telegram.send_message(chat_id, i18n.t("access_denied"))
        logger.warn("unauthorized message from chat " .. tostring(chat_id))
        return
    end

    if msg.document then
        if handle_document(chat_id, msg.document) then return end
    end

    if msg.text then
        if msg.text:sub(1, 1) == "/" then
            handle_command(chat_id, msg.text)
        elseif not handle_awaited_text(chat_id, msg.text) then
            telegram.send_message(chat_id, i18n.t("unknown_command"))
            send_main_menu(chat_id)
        end
    end
end

-- ------------------------------------------------------------------ entry

function M.dispatch(update)
    local ok, err = pcall(function()
        if update.callback_query then
            handle_callback(update)
        elseif update.message then
            handle_message(update)
        end
    end)
    if not ok then
        logger.error("dispatch error: " .. tostring(err))
    end
end

return M
