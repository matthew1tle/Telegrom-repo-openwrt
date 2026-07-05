-- OpenWrt Telegram Bot Panel - Localization Mapping Object
-- Language: English (en)

local M = {}

M.strings = {
    -- Common Elements
    welcome = "🛡️ *OpenWrt Management Bot Panel*\n\nWelcome back, Administrator. Please choose a management block from the control dashboard below.",
    unauthorized = "🚫 Unauthorized access blocked.",
    unknown_action = "❓ Unknown or unmapped operation request.",
    back = "« Back",
    refresh = "🔄 Refresh",
    confirm_title = "⚠️ *Are you absolutely sure?*\nThis operation cannot be safely undone.",
    confirm_yes = "🇾🇪 Yes, Execute",
    confirm_no = "🇳🇴 Cancel",
    enabled = "Enabled",
    disabled = "Disabled",
    status = "Status",

    -- Dashboard / Main Modules
    menu_wifi = "📶 WiFi Networks",
    menu_internet = "🌐 WAN / Internet",
    menu_clients = "👥 Connected Clients",
    menu_pkg = "📦 Packages",
    menu_passwall = "🧱 Passwall2",
    menu_singbox = "⚡ Sing-box",
    menu_system = "💻 System Specs",
    menu_monitor = "📊 Realtime Monitor",

    -- WiFi Submodule
    wifi_title = "📶 *Wireless Infrastructure Management*",
    wifi_ssid = "*SSID:* ",
    wifi_pass = "*Password:* ",
    wifi_chan = "*Channel:* ",
    wifi_enc = "*Encryption:* ",
    wifi_toggle_on = "▶️ Turn WiFi ON",
    wifi_toggle_off = "⏸️ Turn WiFi OFF",
    wifi_change_ssid = "✏️ Edit SSID",
    wifi_change_pass = "🔑 Edit Password",

    -- Internet Submodule
    net_title = "🌐 *Network Interfaces & Gateway*",
    net_pub_ip = "*Public IP:* ",
    net_priv_ip = "*WAN IP:* ",
    net_gw = "*Gateway:* ",
    net_dns = "*DNS Server:* ",
    net_speed_btn = "🚀 Execute Speed Test",
    net_speed_running = "⚡ Running speedtest framework metrics...",

    -- Clients Submodule
    client_title = "👥 *Connected Station Network Map*",
    client_rssi = "Signal: ",
    client_kick = "❌ Kick Client",

    -- Package Manager Submodule
    pkg_title = "📦 *Package Architecture Repository*",
    pkg_upgradable = "*Upgradable Packages:* ",
    pkg_btn_update_list = "🔄 Update Lists",
    pkg_btn_upgrade_all = "🆙 Upgrade All Packages",
    pkg_updating = "📥 Updating internal package layout structures...",

    -- Services: Passwall / Sing-box
    srv_title = "🧱 *Proxy Core Engine Service Matrix*",
    srv_mode = "*Mode:* ",
    srv_btn_start = "▶️ Start Service",
    srv_btn_stop = "⏸️ Stop Service",
    srv_btn_restart = "🔄 Restart Core",

    -- System Submodule
    sys_title = "💻 *System Hardware & Resource Map*",
    sys_cpu = "*CPU Usage:* ",
    sys_ram = "*Memory Architecture:* ",
    sys_flash = "*Storage Partition:* ",
    sys_temp = "*Core Temperature:* ",
    sys_load = "*Load Average:* ",
    sys_uptime = "*Engine Uptime:* ",
    sys_btn_reboot = "🔄 Soft Reboot System",
    sys_btn_shutdown = "🛑 Power Off System",

    -- Realtime Monitor Submodule
    mon_title = "📊 *Realtime Telemetry Pipeline*",
    mon_net_tx = "*WAN Tx Rate:* ",
    mon_net_rx = "*WAN Rx Rate:* ",

    -- Alerts Pipeline Engine
    alert_new_client = "🔔 *Alert: New Client Associated*\n*Host:* %s\n*IP:* %s\n*MAC:* %s",
    alert_high_temp = "🔥 *Critical Thermal Alert!*\n*Current temperature:* %s°C",
    alert_high_ram = "⚠️ *System Memory Starvation Alert!*\n*Current consumption:* %s%%"
}

function M.get(key)
    return M.strings[key] or key
end

return M