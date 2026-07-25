-- OpenWrt Telegram Bot Panel - Localization Mapping Object
-- Language: English (en)

local M = {}

M.strings = {
    -- Common Elements
    welcome = "🛡️ *پنل مدیریت ربات OpenWrt*\n\nبه پنل مدیریت خوش آمدید، مدیر گرامی, لطفاً یکی از بخش‌های مدیریتی را از داشبورد کنترل زیر انتخاب کنید.",
    unauthorized = "🚫 شما دسترسی به این ربات را ندارید",
    unknown_action = "❓ درخواست عملیات نامعتبر یا ناشناخته است.",
    back = "« بازگشت",
    refresh = "🔄 بروزرسانی",
    confirm_title = "⚠️ *آیا کاملا مطمئن هستی؟*\nاین عملیات غیرقابل بازگشت است. لطفاً با دقت ادامه دهید.",
    confirm_yes = "بله مطمئنم",
    confirm_no = "لغو",
    enabled = "فعال",
    disabled = "غیرفعال",
    status = "وضعیت",

    -- Dashboard / Main Modules
    menu_wifi = "📶 WiFi شبکه‌های",
    menu_internet = "🌐 WAN / Internet",
    menu_clients = "👥 کاربران متصل",
    menu_pkg = "📦 Packages",
    menu_passwall = "🧱 Passwall2",
    menu_singbox = "⚡ Sing-box",
    menu_system = "💻 مشخصات دستگاه",
    menu_monitor = "📊 پایش لحظه‌ای",

    -- WiFi Submodule
    wifi_title = "📶 *مدیریت زیرساخت بی‌سیم*",
    wifi_ssid = "*SSID:* ",
    wifi_pass = "*Password:* ",
    wifi_chan = "*Channel:* ",
    wifi_enc = "*Encryption:* ",
    wifi_toggle_on = "▶️ روشن کردن وایفای",
    wifi_toggle_off = "⏸️ خاموش کردن وایفای",
    wifi_change_ssid = "✏️ تغییر نام",
    wifi_change_pass = "🔑 تغییر پسورد",

    -- Internet Submodule
    net_title = "🌐 *Network Interfaces & Gateway*",
    net_pub_ip = "*Public IP:* ",
    net_priv_ip = "*WAN IP:* ",
    net_gw = "*Gateway:* ",
    net_dns = "*DNS Server:* ",
    net_speed_btn = "🚀 تست سرعت",
    net_speed_running = "⚡ در حال انجام تست سرعت",

    -- Clients Submodule
    client_title = "👥 *کاربران متصل*",
    client_rssi = "Signal: ",
    client_kick = "❌ قطع دسترسی",

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