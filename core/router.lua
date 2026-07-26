-- core/router.lua
-- Every incoming update passes through here first for auth, then gets
-- dispatched by command / callback_data prefix to the module that owns it.

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
local passwall = require("modules.passwall")
local singbox = require("modules.singbox")
local backup = require("modules.backup")

local M = {
    allowed_chat_ids = {},
    wan_check_host = "1.1.1.1",
}

local LANGUAGE_NAMES = {
    en = "English",
    fa = "فارسی",
}

function M.init(cfg)
    M.allowed_chat_ids = helpers.split_list(cfg.telegram and cfg.telegram.allowed_chat_ids)
    M.wan_check_host = (cfg.alerts and cfg.alerts.wan_check_host) or M.wan_check_host
end

local function is_authorized(chat_id)
    return helpers.in_list(M.allowed_chat_ids, chat_id)
end

local function send_main_menu(chat_id)
    telegram.send_message(chat_id, "<b>" .. i18n.t("welcome") .. "</b>", keyboards.main_menu())
end

-- ---------------------------------------------------------------- commands

-- Only /start is a typed command. Every other action (system, network,
-- clients, wifi, packages, backup/restore, logs, language) is reachable
-- exclusively through the inline keyboard buttons below - any other typed
-- text just gets pointed back at the menu instead of being parsed as a
-- command.
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

-- ------------------------------------------------------------- callbacks

local function handle_menu(chat_id, message_id, target)
    if target == "main" then
        state.clear(chat_id)
        telegram.edit_message(chat_id, message_id, "<b>" .. i18n.t("welcome") .. "</b>", keyboards.main_menu())
    elseif target == "system" then
        telegram.edit_message(chat_id, message_id, system.render(), keyboards.with_refresh("menu:system"))
    elseif target == "network" then
        telegram.edit_message(chat_id, message_id, monitor.render(), keyboards.with_refresh("menu:network"))
    elseif target == "clients" then
        local text, list = clients.render()
        telegram.edit_message(chat_id, message_id, text, keyboards.clients_list(list))
    elseif target == "wifi" then
        local text, radios = wifi.render()
        telegram.edit_message(chat_id, message_id, text, keyboards.wifi_list(radios))
    elseif target == "packages" then
        telegram.edit_message(chat_id, message_id, pkg.render(), keyboards.with_refresh("menu:packages"))
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

local function handle_clients(chat_id, message_id, action, arg)
    if action == "kick" then
        local ok = clients.kick(arg)
        telegram.send_message(chat_id, ok
            and i18n.t("clients_kick_done", { name = arg })
            or i18n.t("clients_kick_fail", { name = arg }))
        local text, list = clients.render()
        telegram.edit_message(chat_id, message_id, text, keyboards.clients_list(list))
    end
end

local function handle_wifi(chat_id, message_id, action, arg)
    if action == "toggle" then
        wifi.toggle(arg)
        telegram.send_message(chat_id, i18n.t("wifi_toggled", { name = arg }))
        local text, radios = wifi.render()
        telegram.edit_message(chat_id, message_id, text, keyboards.wifi_list(radios))
    end
end

local function handle_backup(chat_id, message_id, action)
    if action == "create" then
        telegram.send_message(chat_id, i18n.t("backup_running"))
        backup.create(chat_id)
    elseif action == "restore" then
        state.set_awaiting(chat_id, "restore_file")
        telegram.send_message(chat_id, i18n.t("restore_prompt"))
    end
end

local function handle_language(chat_id, message_id, code)
    -- Switching languages only needs a config write + reload; every
    -- keyboard/module already reads through i18n.t(), so nothing else in
    -- the codebase needs to change for a new language to "just work".
    helpers.shell(string.format(
        "sed -i 's/^language=.*/language=\"%s\"/' /etc/owrt-tg-bot/config.conf", code
    ))
    i18n.load(code)
    telegram.send_message(chat_id, i18n.t("language_set", { name = LANGUAGE_NAMES[code] or code }))
    send_main_menu(chat_id)
end

local function handle_callback(update)
    local cq = update.callback_query
    local chat_id = cq.message.chat.id
    local message_id = cq.message.message_id
    local data = cq.data or ""

    telegram.answer_callback(cq.id)

    if not is_authorized(chat_id) then
        telegram.send_message(chat_id, i18n.t("access_denied"))
        logger.warn("unauthorized callback from chat " .. tostring(chat_id))
        return
    end

    local kind, a, b = data:match("^(%w+):([%w_]+):?(.*)$")
    if kind == "menu" then
        handle_menu(chat_id, message_id, a)
    elseif kind == "clients" then
        handle_clients(chat_id, message_id, a, b)
    elseif kind == "wifi" then
        handle_wifi(chat_id, message_id, a, b)
    elseif kind == "backup" then
        handle_backup(chat_id, message_id, a)
    elseif kind == "lang" and a == "set" then
        handle_language(chat_id, message_id, b)
    end
end

-- --------------------------------------------------------------- messages

-- A file arriving while state.awaiting == "restore_file" is treated as a
-- restore upload rather than a normal chat message.
local function handle_document(chat_id, document)
    if state.awaiting(chat_id) ~= "restore_file" then return false end
    state.set_awaiting(chat_id, nil)

    telegram.send_message(chat_id, i18n.t("restore_running"))
    local dest = "/tmp/owrt-tg-bot-restore.tar.gz"
    local ok, err = telegram.download_file(document.file_id, dest)
    if not ok then
        telegram.send_message(chat_id, i18n.t("restore_failed", { reason = err or "download" }))
        return true
    end

    local restored, reason = backup.restore(dest)
    if restored then
        telegram.send_message(chat_id, i18n.t("restore_done"))
    elseif reason == "not_a_backup" then
        telegram.send_message(chat_id, i18n.t("restore_wrong_file"))
    else
        telegram.send_message(chat_id, i18n.t("restore_failed", { reason = reason or "unknown" }))
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
        handle_command(chat_id, msg.text)
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
