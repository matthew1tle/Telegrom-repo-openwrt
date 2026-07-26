-- lang/en.lua
-- Canonical string table. This is the fallback for every other language,
-- so every key the bot ever uses must exist here. When adding a new
-- language file, keep the same keys - only the values change.

return {
    -- general / auth
    access_denied = "Access denied. Your chat ID is not on the allow-list.",
    welcome = "OpenWrt control panel ready. Choose an option below.",
    error_generic = "Something went wrong. Check /logs for details.",
    unknown_command = "Please use the buttons below - only /start is a typed command.",

    -- main menu
    menu_title = "Main menu",
    btn_system = "System",
    btn_network = "Network",
    btn_clients = "Clients",
    btn_wifi = "Wi-Fi",
    btn_packages = "Packages",
    btn_backup = "Backup / Restore",
    btn_logs = "Logs",
    btn_language = "Language",
    btn_back = "Back",
    btn_refresh = "Refresh",

    -- system module
    system_title = "System status",
    system_cpu = "CPU load: %{value}",
    system_mem = "Memory used: %{used} / %{total} (%{percent}%%)",
    system_disk = "Flash used: %{used} / %{total} (%{percent}%%)",
    system_uptime = "Uptime: %{value}",

    -- network / monitor / internet
    network_title = "Network",
    network_rx = "RX: %{value}/s",
    network_tx = "TX: %{value}/s",
    internet_ping_ok = "WAN reachable (%{host}), %{ms} ms",
    internet_ping_fail = "WAN unreachable (%{host})",
    internet_speedtest_running = "Running a quick speed check...",
    internet_speedtest_result = "Download: ~%{mbps} Mbps",

    -- clients
    clients_title = "Connected clients",
    clients_none = "No DHCP leases found.",
    clients_kick_done = "Disconnected %{name}.",
    clients_kick_fail = "Could not disconnect %{name}.",

    -- wifi
    wifi_title = "Wi-Fi radios",
    wifi_enabled = "%{name}: enabled",
    wifi_disabled = "%{name}: disabled",
    wifi_toggled = "%{name} toggled. Reloading Wi-Fi...",

    -- packages
    packages_title = "Packages",
    packages_installed_count = "%{count} packages installed.",
    packages_upgrade_available = "%{count} updates available.",
    packages_up_to_date = "System is up to date.",

    -- passwall / singbox
    passwall_status = "Passwall2: %{status}",
    singbox_status = "sing-box: %{status}",
    service_toggled = "%{name} is now %{status}.",

    -- backup / restore
    backup_title = "Backup / Restore",
    backup_running = "Creating a configuration backup...",
    backup_done_caption = "Router config backup - %{date}",
    backup_failed = "Backup failed. Check /logs.",
    restore_prompt = "Send the .tar.gz backup file to restore.",
    restore_running = "Restoring configuration...",
    restore_done = "Restore complete. A reboot is required for all changes to take effect.",
    restore_failed = "Restore failed: %{reason}",
    restore_wrong_file = "That doesn't look like a backup file created by this bot.",

    -- language
    language_title = "Choose a language",
    language_set = "Language set to %{name}.",

    -- alerts
    alert_cpu_high = "⚠️ High CPU load: %{value}",
    alert_mem_high = "⚠️ High memory use: %{percent}%%",
    alert_disk_high = "⚠️ High flash use: %{percent}%%",
    alert_wan_down = "🔴 WAN connectivity lost (%{host}).",
    alert_wan_recovered = "🟢 WAN connectivity restored (%{host}).",

    -- logs
    logs_title = "Recent log lines",
}
