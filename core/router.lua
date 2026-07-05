-- OpenWrt Telegram Bot Panel - Event Routing and Action State Mapping Engine
local telegram = require("core.telegram")
local state_machine = require("core.state")
local kb_engine = require("keyboards.engine")
local lang = require("lang.en") -- Switched back to English
local helpers = require("core.helpers")
local logger = require("core.logger")

-- Load Submodules
local wifi = require("modules.wifi")
local internet = require("modules.internet")
local clients = require("modules.clients")
local package = require("modules.package")
local passwall = require("modules.passwall")
local singbox = require("modules.singbox")
local system = require("modules.system")
local monitor = require("modules.monitor")

local M = {}

local function send_main_menu(chat_id, message_id)
    local kb = kb_engine.create()
    kb_engine.add_row(kb, {
        { text = lang.get("menu_wifi") or "📶 Wi-Fi Settings", callback_data = "nav_wifi" },
        { text = lang.get("menu_internet") or "🌐 WAN / Internet", callback_data = "nav_internet" }
    })
    kb_engine.add_row(kb, {
        { text = lang.get("menu_clients") or "👥 Clients List", callback_data = "nav_clients" },
        { text = lang.get("menu_pkg") or "📦 Packages", callback_data = "nav_pkg" }
    })
    kb_engine.add_row(kb, {
        { text = lang.get("menu_passwall") or "🧱 Passwall", callback_data = "nav_passwall" },
        { text = lang.get("menu_singbox") or "⚡ Sing-box", callback_data = "nav_singbox" }
    })
    kb_engine.add_row(kb, {
        { text = lang.get("menu_system") or "💻 System Specs", callback_data = "nav_system" },
        { text = lang.get("menu_monitor") or "📊 Live Monitor", callback_data = "nav_monitor" }
    })

    local markup = kb_engine.export(kb)
    state_machine.transition_to(chat_id, "main", true)

    if message_id then
        telegram.edit_message(chat_id, message_id, lang.get("welcome") or "🎮 *OpenWrt Router Control Board*", markup)
    else
        telegram.send_message(chat_id, lang.get("welcome") or "🎮 *OpenWrt Router Control Board*", markup)
    end
end

-- Processes Interactive Text Input Framework Messages
function M.handle_message(msg)
    local chat_id = msg.chat.id
    local text = msg.text

    if not telegram.is_authorized(chat_id) then return end

    if text == "/start" then
        state_machine.clear_state(chat_id)
        send_main_menu(chat_id, nil)
        return
    end

    local current_state = state_machine.get_state(chat_id) or {}
    
    if current_state.name == "wait_ssid" then
        local target_section = current_state.context
        wifi.change_ssid(target_section, text)
        state_machine.clear_state(chat_id)
        telegram.send_message(chat_id, "✅ *SSID Updated Successfully!* Re-applying radio configurations...")
        send_main_menu(chat_id, nil)
        
    elseif current_state.name == "wait_pass" then
        local target_section = current_state.context
        wifi.change_password(target_section, text)
        state_machine.clear_state(chat_id)
        telegram.send_message(chat_id, "✅ *Wireless Password Updated!* Restarting wireless radio layers...")
        send_main_menu(chat_id, nil)
        
    else
        telegram.send_message(chat_id, "⚠️ Please use the interactive option buttons to issue terminal commands.")
    end
end

-- Dispatches Callbacks Across Submodules
function M.handle_callback(callback)
    local chat_id = callback.message.chat.id
    local message_id = callback.message.message_id
    local data = callback.data
    local query_id = callback.id

    if not telegram.is_authorized(chat_id) then return end

    -- Navigation callback click immediately flushes text-wait states
    if data:match("^nav_") or data == "nav_main" then
        state_machine.clear_state(chat_id)
    end

    if data == "nav_main" then
        send_main_menu(chat_id, message_id)
        telegram.answer_callback(query_id)

    elseif data == "nav_wifi" then
        local text = wifi.get_wifi_summary()
        local kb = kb_engine.create()
        local nets = wifi.get_wifi_networks()
        
        for _, net in ipairs(nets) do
            kb_engine.add_row(kb, {
                { text = "⚙️ Configure " .. net.section, callback_data = "wifi_manage_" .. net.section }
            })
        end
        kb_engine.add_control_row(kb, "nav_main", "nav_wifi")
        telegram.edit_message(chat_id, message_id, text, kb_engine.export(kb))
        telegram.answer_callback(query_id)

    elseif data:match("^wifi_manage_") then
        local section = data:match("^wifi_manage_(.+)")
        local nets = wifi.get_wifi_networks()
        local current_net = nil
        for _, n in ipairs(nets) do if n.section == section then current_net = n break end end
        
        if current_net then
            local text = string.format("🛠️ *Managing Interface:* `%s`\nCurrent SSID: `%s`\nEncryption: `%s`", section, current_net.ssid, current_net.encryption)
            local kb = kb_engine.create()
            local toggle_label = current_net.enabled and "⏸️ Disable Radio" or "▶️ Enable Radio"
            
            kb_engine.add_row(kb, {
                { text = toggle_label, callback_data = "wifi_toggle_" .. section .. "_" .. (current_net.enabled and "0" or "1") }
            })
            kb_engine.add_row(kb, {
                { text = "📝 Edit SSID", callback_data = "wifi_reqssid_" .. section },
                { text = "🔑 Edit Password", callback_data = "wifi_reqpass_" .. section }
            })
            kb_engine.add_control_row(kb, "nav_wifi", "nav_wifi")
            telegram.edit_message(chat_id, message_id, text, kb_engine.export(kb))
        end
        telegram.answer_callback(query_id)

    elseif data:match("^wifi_toggle_") then
        local section, target_state = data:match("^wifi_toggle_(.+)_(%d+)$")
        wifi.toggle_wifi(section, target_state == "1")
        telegram.answer_callback(query_id, "Wireless interface updated.", false)
        helpers.exec("sleep 1")
        send_main_menu(chat_id, message_id)

    elseif data:match("^wifi_reqssid_") then
        local section = data:match("^wifi_reqssid_(.+)")
        state_machine.transition_to(chat_id, { name = "wait_ssid", context = section })
        
        local kb = kb_engine.create()
        kb_engine.add_control_row(kb, "nav_wifi", "nav_wifi")
        telegram.edit_message(chat_id, message_id, "📝 *Type the new Wi-Fi name (SSID)* and send it as a text message now:", kb_engine.export(kb))
        telegram.answer_callback(query_id)

    elseif data:match("^wifi_reqpass_") then
        local section = data:match("^wifi_reqpass_(.+)")
        state_machine.transition_to(chat_id, { name = "wait_pass", context = section })
        
        local kb = kb_engine.create()
        kb_engine.add_control_row(kb, "nav_wifi", "nav_wifi")
        telegram.edit_message(chat_id, message_id, "🔑 *Type the new Wi-Fi Password* (minimum 8 characters) and send it as a text message now:", kb_engine.export(kb))
        telegram.answer_callback(query_id)

    elseif data == "nav_internet" then
        local text = internet.get_internet_summary()
        local kb = kb_engine.create()
        kb_engine.add_row(kb, { { text = lang.get("net_speed_btn") or "🚀 Run Speed Test", callback_data = "net_speedtest" } })
        kb_engine.add_control_row(kb, "nav_main", "nav_internet")
        telegram.edit_message(chat_id, message_id, text, kb_engine.export(kb))
        telegram.answer_callback(query_id)

    elseif data == "net_speedtest" then
        telegram.answer_callback(query_id, lang.get("net_speed_running") or "Running speed test...", false)
        local results = internet.run_speedtest()
        local kb = kb_engine.create()
        kb_engine.add_control_row(kb, "nav_main", "nav_internet")
        telegram.edit_message(chat_id, message_id, results, kb_engine.export(kb))

    elseif data == "nav_clients" then
        local text = clients.get_clients_summary()
        local kb = kb_engine.create()
        kb_engine.add_control_row(kb, "nav_main", "nav_clients")
        telegram.edit_message(chat_id, message_id, text, kb_engine.export(kb))
        telegram.answer_callback(query_id)

    elseif data == "nav_pkg" then
        local text = package.get_package_summary()
        local kb = kb_engine.create()
        kb_engine.add_control_row(kb, "nav_main", "nav_pkg")
        telegram.edit_message(chat_id, message_id, text, kb_engine.export(kb))
        telegram.answer_callback(query_id)

    elseif data == "nav_passwall" then
        local text = passwall.get_summary()
        local kb = kb_engine.create()
        kb_engine.add_control_row(kb, "nav_main", "nav_passwall")
        telegram.edit_message(chat_id, message_id, text, kb_engine.export(kb))
        telegram.answer_callback(query_id)

    elseif data == "nav_singbox" then
        local text = singbox.get_summary()
        local kb = kb_engine.create()
        kb_engine.add_control_row(kb, "nav_main", "nav_singbox")
        telegram.edit_message(chat_id, message_id, text, kb_engine.export(kb))
        telegram.answer_callback(query_id)

    elseif data == "nav_system" then
        local text = system.get_metrics_summary()
        local kb = kb_engine.create()
        kb_engine.add_control_row(kb, "nav_main", "nav_system")
        telegram.edit_message(chat_id, message_id, text, kb_engine.export(kb))
        telegram.answer_callback(query_id)

    elseif data == "nav_monitor" then
        telegram.answer_callback(query_id, "Calculating bandwidth statistics...", false)
        local rx, tx = monitor.get_realtime_stats()
        local title = lang.get("mon_title") or "📊 *Realtime Network Stats*"
        local rx_lbl = lang.get("mon_net_rx") or "📥 Download: "
        local tx_lbl = lang.get("mon_net_tx") or "📤 Upload: "
        local text = string.format("%s\n\n%s`%s/s`\n%s`%s/s`", title, rx_lbl, helpers.format_bytes(rx), tx_lbl, helpers.format_bytes(tx))
        local kb = kb_engine.create()
        kb_engine.add_control_row(kb, "nav_main", "nav_monitor")
        telegram.edit_message(chat_id, message_id, text, kb_engine.export(kb))
    else
        telegram.answer_callback(query_id, lang.get("unknown_action") or "Unknown action.", true)
    end
end

return M