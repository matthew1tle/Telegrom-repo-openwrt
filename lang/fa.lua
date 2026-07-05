-- OpenWrt Telegram Bot Panel - Persian (فارسی) Language Schema Strings Map
local M = {
    -- Welcome & Global Control Action UI
    welcome = "🎮 *منوی کنترل پنل مدیریت روتر OpenWrt*",
    unauthorized = "⛔ خطا: شما مجاز به استفاده از این ربات نیستید!",
    unknown_action = "⚠️ دستور وارد شده نامعتبر است.",
    confirm_title = "❓ آیا از انجام این عملیات اطمینان دارید؟",
    
    -- Main Keyboard Menu Bindings
    menu_wifi = "📶 تنظیمات وای‌فای",
    menu_internet = "🌐 وضعیت اینترنت / WAN",
    menu_clients = "👥 کاربران متصل",
    menu_pkg = "📦 مدیریت پکیج‌ها",
    menu_passwall = "🧱 پروکسی Passwall",
    menu_singbox = "⚡ پروکسی Sing-box",
    menu_system = "💻 مشخصات سیستم",
    menu_monitor = "📊 مانیتورینگ زنده",
    
    -- Wireless Module UI
    wifi_title = "📶 *مدیریت شبکه‌های وای‌فای*",
    wifi_ssid = "نام شبکه (SSID): ",
    wifi_pass = "رمز عبور: ",
    wifi_chan = "کانال: ",
    wifi_enc = "رمزگذاری: ",
    wifi_state = "وضعیت: ",
    wifi_enabled = "فعال",
    wifi_disabled = "غیرفعال",
    
    -- Internet/WAN Module UI
    net_title = "🌐 *خلاصه وضعیت اتصال اینترنت / WAN*",
    net_status = "*وضعیت اتصال:* ",
    net_pub_ip = "*آی‌پی عمومی (Public IP):* ",
    net_priv_ip = "*آی‌پی محلی (Private IP):* ",
    net_gw = "*گیت‌وی (Gateway):* ",
    net_dns = "*سرورهای دی‌ان‌اس (DNS):* ",
    net_speed_btn = "🚀 تست سرعت اینترنت",
    net_speed_running = "در حال ارزیابی سرعت شبکه از طریق سرورهای کلودفلر...",
    
    -- System Resource UI
    sys_title = "💻 *مشخصات و منابع سخت‌افزاری سیستم*",
    sys_model = "*سخت‌افزار:* ",
    sys_load = "*میانگین بار پردازش:* ",
    sys_ram = "*فضای رم اشغال شده:* ",
    sys_flash = "*حافظه ذخیره‌سازی:* ",
    sys_temp = "*دمای پردازنده:* ",
    sys_uptime = "*مدت زمان روشن بودن:* ",
    sys_btn_reboot = "🔄 ری‌بوت روتر",
    sys_btn_shutdown = "🔌 خاموش کردن روتر",
    
    -- Realtime Bandwidth Monitor UI
    mon_title = "📊 *آمار مانیتورینگ زنده پهنای باند شبکه*",
    mon_net_rx = "📥 سرعت دانلود: ",
    mon_net_tx = "📤 سرعت آپلود: "
}

return M