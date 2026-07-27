-- lang/en.lua
-- Canonical string table. This is the fallback for every other language,
-- so every key the bot ever uses must exist here. When adding a new
-- language file, keep the same keys - only the values change.

return {
    -- general / auth
    access_denied = "🚫 Access denied. Your chat ID is not on the allow-list.",
    welcome = "👋 OpenWrt control panel ready. Choose an option below.",
    error_generic = "⚠️ Something went wrong. Check 📄 Logs for details.",
    unknown_command = "🤖 Please use the buttons below - only /start is a typed command.",

    -- main menu
    menu_title = "🏠 Main menu",
    btn_system = "🖥️ System",
    btn_network = "🌐 Network",
    btn_clients = "👥 Clients",
    btn_wifi = "📶 Wi-Fi",
    btn_packages = "📦 Packages",
    btn_backup = "💾 Backup / Restore",
    btn_logs = "📄 Logs",
    btn_language = "🌍 Language",
    btn_back = "◀️ Back",
    btn_refresh = "🔄 Refresh",
    btn_cancel = "❌ Cancel",
    btn_backup_create = "💾 Create backup",
    btn_backup_restore = "♻️ Restore",
    btn_packages_list = "📋 Update list",
    btn_block_5 = "⏱ 5 min",
    btn_block_30 = "⏱ 30 min",
    btn_block_60 = "⏱ 1 hour",
    btn_unblock = "🔓 Unblock now",
    btn_wifi_turn_on = "🟢 Turn on",
    btn_wifi_turn_off = "🔴 Turn off",
    btn_wifi_rename = "✏️ Change name",
    btn_wifi_password = "🔑 Change password",
    btn_speedtest = "🚀 Speed test",

    -- system module
    system_title = "🖥️ System status",
    system_cpu = "⚙️ CPU load: %{value}",
    system_temp = "🌡️ CPU temperature: %{value}°C",
    system_mem = "🧠 Memory used: %{used} / %{total} (%{percent}%%)",
    system_disk = "💽 Flash used: %{used} / %{total} (%{percent}%%)",
    system_uptime = "⏳ Uptime: %{value}",

    -- network / monitor / internet
    network_title = "🌐 Network",
    network_rx = "⬇️ RX: %{value}/s",
    network_tx = "⬆️ TX: %{value}/s",
    internet_ping_ok = "✅ WAN reachable (%{host}), %{ms} ms",
    internet_ping_fail = "❌ WAN unreachable (%{host})",
    internet_speedtest_running = "⏳ Running a speed check, this can take a moment...",
    internet_speedtest_result = "🚀 Download: ~%{mbps} Mbps (estimate)",
    internet_speedtest_download = "🚀 Download: %{mbps} Mbps",
    internet_speedtest_upload = "📤 Upload: %{mbps} Mbps",
    internet_speedtest_ping = "📶 Ping: %{ms} ms",
    internet_speedtest_server = "🌐 Server: %{name}",
    internet_public_ip = "🌍 Public IP: <code>%{ip}</code>",
    internet_ip_unknown = "🌍 Public IP: unavailable",

    -- clients
    clients_title = "👥 Connected clients",
    clients_none = "😶 No DHCP leases found.",
    clients_detail_status_ok = "🟢 %{name} has full access.",
    clients_detail_status_blocked = "🚫 %{name} is currently blocked.",
    clients_block_done = "🚫 %{name} blocked for %{minutes} min.",
    clients_block_fail = "⚠️ Could not block %{name}.",
    clients_unblock_done = "🔓 %{name} unblocked.",

    -- wifi
    wifi_title = "📶 Wi-Fi radios",
    wifi_enabled = "🟢 %{name}: enabled",
    wifi_disabled = "🔴 %{name}: disabled",
    wifi_detail_header = "📶 <b>%{name}</b>",
    wifi_turned_on = "🟢 %{name} turned on. Reloading Wi-Fi...",
    wifi_turned_off = "🔴 %{name} turned off. Reloading Wi-Fi...",
    wifi_rename_prompt = "✏️ Send the new Wi-Fi name (SSID), 1-32 characters.",
    wifi_ssid_updated = "✅ Wi-Fi name updated. Reloading Wi-Fi...",
    wifi_ssid_invalid = "⚠️ That name isn't valid (1-32 characters). Try again, or Cancel.",
    wifi_password_prompt = "🔑 Send the new Wi-Fi password, 8-63 characters.",
    wifi_password_updated = "✅ Wi-Fi password updated. Reloading Wi-Fi...",
    wifi_password_invalid = "⚠️ Password must be 8-63 characters. Try again, or Cancel.",

    -- packages
    packages_title = "📦 Packages",
    packages_installed_count = "📦 %{count} packages installed.",
    packages_upgrade_available = "⬆️ %{count} updates available.",
    packages_up_to_date = "✅ System is up to date.",
    packages_updates_list_header = "📋 <b>Packages with updates available</b>",
    packages_updates_list_empty = "✅ Nothing to update.",

    -- passwall / singbox
    passwall_status = "🛡️ Passwall2: %{status}",
    singbox_status = "🛡️ sing-box: %{status}",
    service_toggled = "🔁 %{name} is now %{status}.",

    -- backup / restore
    backup_title = "💾 Backup / Restore",
    backup_running = "⏳ Creating a configuration backup...",
    backup_done_caption = "💾 Router config backup - %{date}",
    backup_failed = "⚠️ Backup failed. Check 📄 Logs.",
    restore_prompt = "♻️ Send the .tar.gz backup file to restore, or Cancel.",
    restore_done = "✅ Restore complete. A reboot is required for all changes to take effect.",
    restore_failed = "⚠️ Restore failed: %{reason}",
    restore_wrong_file = "❌ That doesn't look like a backup file created by this bot.",

    -- language
    language_title = "🌍 Choose a language",
    language_set = "✅ Language set to %{name}.",

    -- alerts
    alert_cpu_high = "⚠️ High CPU load: %{value}",
    alert_mem_high = "⚠️ High memory use: %{percent}%%",
    alert_disk_high = "⚠️ High flash use: %{percent}%%",
    alert_temp_high = "🌡️ High CPU temperature: %{value}°C",
    alert_wan_down = "🔴 WAN connectivity lost (%{host}).",
    alert_wan_recovered = "🟢 WAN connectivity restored (%{host}).",

    -- logs
    logs_title = "📄 Recent log lines",
}
