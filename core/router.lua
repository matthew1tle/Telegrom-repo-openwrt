-- OpenWrt Telegram Bot Panel - Event Routing and Action State Mapping Engine
-- Orchestrates navigation matrices and inbound inline callback updates

local telegram = require("core.telegram")
local state_machine = require("core.state")
local kb_engine = require("keyboards.engine")
local lang = require("lang.en")
local logger = require("core.logger")

-- Load Submodules safely
local wifi = require("modules.wifi")
local internet = require("modules.internet")
local clients = require("modules.clients")
local package = require("modules.package")
local passwall = require("modules.passwall")
local singbox = require("modules.singbox")
local system = require("modules.system")
local monitor = require("modules.monitor")

local M = {}

-- Main Control Dashboard Menu Matrix
local function send_main_menu(chat_id, message_id)
    local kb = kb_engine.create()
    kb_engine.add_row(kb, {
        { text = lang.get("menu_wifi"), callback_data = "nav_wifi" },
        { text = lang.get("menu_internet"), callback_data = "nav_internet" }
    })
    kb_engine.add_row(kb, {
        { text = lang.get("menu_clients"), callback_data = "nav_clients" },
        { text = lang.get("menu_pkg"), callback_data = "nav_pkg" }
    })
    kb_engine.add_row(kb, {
        { text = lang.get("menu_passwall"), callback_data = "nav_passwall" },
        { text = lang.get("menu_singbox"), callback_data = "nav_singbox" }
    })
    kb_engine.add_row(kb, {
        { text = lang.get("menu_system"), callback_data = "nav_system" },
        { text = lang.get("menu_monitor"), callback_data = "nav_monitor" }
    })

    local markup = kb_engine.export(kb)
    state_machine.transition_to(chat_id, "main", true)

    if message_id then
        telegram.edit_message(chat_id, message_id, lang.get("welcome"), markup)
    else
        telegram.send_message(chat_id, lang.get("welcome"), markup)
    end
end

-- Processes Text Commands Safely (Strict /start validation filter)
function M.handle_message(msg)
    local chat_id = msg.chat.id
    local text = msg.text

    if not telegram.is_authorized(chat_id) then
        telegram.send_message(chat_id, lang.get("unauthorized"))
        logger.warn(string.format("Unauthorized system text interaction attempted by ID: %s", tostring(chat_id)))
        return
    end

    if text == "/start" then
        send_main_menu(chat_id, nil)
    else
        -- Absolute denial of raw typed structural updates to maintain inline control framework boundaries
        telegram.send_message(chat_id, "⚠️ Operations are exclusively managed via interactive control buttons.")
    end
end

-- Dispatches Callbacks across target application submodules
function M.handle_callback(callback)
    local chat_id = callback.message.chat.id
    local message_id = callback.message.message_id
    local data = callback.data
    local query_id = callback.id

    if not telegram.is_authorized(chat_id) then
        telegram.answer_callback(query_id, lang.get("unauthorized"), true)
        return
    end

    logger.debug(string.format("Processing callback mutation event: %s from user: %s", data, tostring(chat_id)))

    -- Global Navigation Event Router Mapping Matrix
    if data == "nav_main" then
        send_main_menu(chat_id, message_id)
        telegram.answer_callback(query_id)

    elseif data == "nav_wifi" then
        local text = wifi.get_wifi_summary()
        local kb = kb_engine.create()
        local nets = wifi.get_wifi_networks()
        for _, net in ipairs(nets) do
            local toggle_text = net.enabled and "⏸️ Turn OFF " or "▶️ Turn ON "
            kb_engine.add_row(kb, {
                { text = toggle_text .. net.ssid, callback_data = "wifi_toggle_" .. net.section .. "_" .. (net.enabled and "0" or "1") }
            })
        end
        kb_engine.add_control_row(kb, "nav_main", "nav_wifi")
        telegram.edit_message(chat_id, message_id, text, kb_engine.export(kb))
        telegram.answer_callback(query_id)

    elseif data:match("^wifi_toggle_") then
        local section, target_state = data:match("^wifi_toggle_(.+电%[.-%])_(%d+)")
        if not section then section, target_state = data:match("^wifi_toggle_(.+)_(%d+)") end
        wifi.toggle_wifi(section, target_state == "1")
        telegram.answer_callback(query_id, "Wireless topology configuration applied.", false)
        helpers.exec("sleep 1")
        local text = wifi.get_wifi_summary()
        local kb = kb_engine.create()
        kb_engine.add_control_row(kb, "nav_main", "nav_wifi")
        telegram.edit_message(chat_id, message_id, text, kb_engine.export(kb))

    elseif data == "nav_internet" then
        local text = internet.get_internet_summary()
        local kb = kb_engine.create()
        kb_engine.add_row(kb, {
            { text = lang.get("net_speed_btn"), callback_data = "net_speedtest" }
        })
        kb_engine.add_control_row(kb, "nav_main", "nav_internet")
        telegram.edit_message(chat_id, message_id, text, kb_engine.export(kb))
        telegram.answer_callback(query_id)

    elseif data == "net_speedtest" then
        telegram.answer_callback(query_id, lang.get("net_speed_running"), false)
        local results = internet.run_speedtest()
        local kb = kb_engine.create()
        kb_engine.add_control_row(kb, "nav_main", "nav_internet")
        telegram.edit_message(chat_id, message_id, results, kb_engine.export(kb))

    elseif data == "nav_clients" then
        local text = clients.get_clients_summary()
        local kb = kb_engine.create()
        local active_map = clients.get_connected_clients()
        for mac, client in pairs(active_map) do
            if client.rssi then -- Client is wireless, expose kick capability
                kb_engine.add_row(kb, {
                    { text = "❌ Kick " .. client.hostname, callback_data = "client_kick_" .. mac }
                })
            end
        end
        kb_engine.add_control_row(kb, "nav_main", "nav_clients")
        telegram.edit_message(chat_id, message_id, text, kb_engine.export(kb))
        telegram.answer_callback(query_id)

    elseif data:match("^client_kick_") then
        local target_mac = data:match("^client_kick_(.+)")
        clients.kick_client(target_mac)
        telegram.answer_callback(query_id, "Wireless interface client kicked.", true)
        local text = clients.get_clients_summary()
        local kb = kb_engine.create()
        kb_engine.add_control_row(kb, "nav_main", "nav_clients")
        telegram.edit_message(chat_id, message_id, text, kb_engine.export(kb))

    elseif data == "nav_pkg" then
        local text = package.get_package_summary()
        local kb = kb_engine.create()
        kb_engine.add_row(kb, {
            { text = lang.get("pkg_btn_update_list"), callback_data = "pkg_update_lists" },
            { text = lang.get("pkg_btn_upgrade_all"), callback_data = "pkg_upgrade_confirm" }
        })
        kb_engine.add_control_row(kb, "nav_main", "nav_pkg")
        telegram.edit_message(chat_id, message_id, text, kb_engine.export(kb))
        telegram.answer_callback(query_id)

    elseif data == "pkg_update_lists" then
        telegram.answer_callback(query_id, lang.get("pkg_updating"), false)
        package.update_package_lists()
        local text = package.get_package_summary()
        local kb = kb_engine.create()
        kb_engine.add_control_row(kb, "nav_main", "nav_pkg")
        telegram.edit_message(chat_id, message_id, text, kb_engine.export(kb))

    elseif data == "pkg_upgrade_confirm" then
        local confirmation_kb = kb_engine.build_confirmation("pkg_upgrade_execute", "nav_pkg")
        telegram.edit_message(chat_id, message_id, lang.get("confirm_title"), kb_engine.export(confirmation_kb))
        telegram.answer_callback(query_id)

    elseif data == "pkg_upgrade_execute" then
        telegram.answer_callback(query_id, "Upgrading core components, please wait...", false)
        package.upgrade_all_packages()
        send_main_menu(chat_id, message_id)

    elseif data == "nav_passwall" then
        local text = passwall.get_summary()
        local current = passwall.get_status()
        local kb = kb_engine.create()
        local toggle_label = current.running and lang.get("srv_btn_stop") or lang.get("srv_btn_start")
        kb_engine.add_row(kb, {
            { text = toggle_label, callback_data = "passwall_toggle_" .. (current.running and "0" or "1") },
            { text = lang.get("srv_btn_restart"), callback_data = "passwall_restart" }
        })
        kb_engine.add_control_row(kb, "nav_main", "nav_passwall")
        telegram.edit_message(chat_id, message_id, text, kb_engine.export(kb))
        telegram.answer_callback(query_id)

    elseif data:match("^passwall_toggle_") then
        local state = data:match("passwall_toggle_(%d+)") == "1"
        passwall.toggle(state)
        telegram.answer_callback(query_id, "Processing Passwall operational change.", false)
        helpers.exec("sleep 1.5")
        local text = passwall.get_summary()
        local kb = kb_engine.create()
        kb_engine.add_control_row(kb, "nav_main", "nav_passwall")
        telegram.edit_message(chat_id, message_id, text, kb_engine.export(kb))

    elseif data == "passwall_restart" then
        passwall.restart()
        telegram.answer_callback(query_id, "Passwall framework core restarted.", false)

    elseif data == "nav_singbox" then
        local text = singbox.get_summary()
        local current = singbox.get_status()
        local kb = kb_engine.create()
        local toggle_label = current.running and lang.get("srv_btn_stop") or lang.get("srv_btn_start")
        kb_engine.add_row(kb, {
            { text = toggle_label, callback_data = "singbox_toggle_" .. (current.running and "0" or "1") },
            { text = lang.get("srv_btn_restart"), callback_data = "singbox_restart" }
        })
        kb_engine.add_control_row(kb, "nav_main", "nav_singbox")
        telegram.edit_message(chat_id, message_id, text, kb_engine.export(kb))
        telegram.answer_callback(query_id)

    elseif data:match("^singbox_toggle_") then
        local state = data:match("singbox_toggle_(%d+)") == "1"
        singbox.toggle(state)
        telegram.answer_callback(query_id, "Processing Sing-box operational change.", false)
        helpers.exec("sleep 1.5")
        local text = singbox.get_summary()
        local kb = kb_engine.create()
        kb_engine.add_control_row(kb, "nav_main", "nav_singbox")
        telegram.edit_message(chat_id, message_id, text, kb_engine.export(kb))

    elseif data == "singbox_restart" then
        singbox.restart()
        telegram.answer_callback(query_id, "Sing-box architecture engine restarted.", false)

    elseif data == "nav_system" then
        local text = system.get_metrics_summary()
        local kb = kb_engine.create()
        kb_engine.add_row(kb, {
            { text = lang.get("sys_btn_reboot"), callback_data = "sys_reboot_confirm" },
            { text = lang.get("sys_btn_shutdown"), callback_data = "sys_shutdown_confirm" }
        })
        kb_engine.add_control_row(kb, "nav_main", "nav_system")
        telegram.edit_message(chat_id, message_id, text, kb_engine.export(kb))
        telegram.answer_callback(query_id)

    elseif data == "sys_reboot_confirm" then
        local confirmation_kb = kb_engine.build_confirmation("sys_reboot_execute", "nav_system")
        telegram.edit_message(chat_id, message_id, lang.get("confirm_title"), kb_engine.export(confirmation_kb))
        telegram.answer_callback(query_id)

    elseif data == "sys_reboot_execute" then
        telegram.answer_callback(query_id, "Initiating hardware reset pipeline...", true)
        system.execute_reboot()

    elseif data == "sys_shutdown_confirm" then
        local confirmation_kb = kb_engine.build_confirmation("sys_shutdown_execute", "nav_system")
        telegram.edit_message(chat_id, message_id, lang.get("confirm_title"), kb_engine.export(confirmation_kb))
        telegram.answer_callback(query_id)

    elseif data == "sys_shutdown_execute" then
        telegram.answer_callback(query_id, "Executing soft hardware shutdown sequence...", true)
        system.execute_shutdown()

    elseif data == "nav_monitor" then
        telegram.answer_callback(query_id, "Gathering active interface