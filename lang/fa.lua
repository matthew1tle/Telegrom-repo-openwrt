-- lang/fa.lua
-- Persian translation. Same keys as lang/en.lua - only values differ.
-- Any key left out here is filled in automatically from English by
-- core/i18n.lua, so it's safe to translate incrementally.

return {
    access_denied = "دسترسی رد شد. شناسه چت شما در لیست مجاز نیست.",
    welcome = "پنل کنترل روتر آماده است. یک گزینه را انتخاب کنید.",
    error_generic = "خطایی رخ داد. برای جزئیات /logs را بررسی کنید.",
    unknown_command = "لطفاً از دکمه‌های زیر استفاده کنید - فقط /start به‌صورت تایپی کار می‌کند.",

    menu_title = "منوی اصلی",
    btn_system = "سیستم",
    btn_network = "شبکه",
    btn_clients = "کلاینت‌ها",
    btn_wifi = "وای‌فای",
    btn_packages = "پکیج‌ها",
    btn_backup = "پشتیبان‌گیری / بازیابی",
    btn_logs = "لاگ‌ها",
    btn_language = "زبان",
    btn_back = "بازگشت",
    btn_refresh = "بروزرسانی",

    system_title = "وضعیت سیستم",
    system_cpu = "بار پردازنده: %{value}",
    system_mem = "حافظه مصرفی: %{used} / %{total} (%{percent}%%)",
    system_disk = "فضای فلش مصرفی: %{used} / %{total} (%{percent}%%)",
    system_uptime = "مدت روشن بودن: %{value}",

    network_title = "شبکه",
    network_rx = "دریافتی: %{value} در ثانیه",
    network_tx = "ارسالی: %{value} در ثانیه",
    internet_ping_ok = "اینترنت متصل است (%{host})، %{ms} میلی‌ثانیه",
    internet_ping_fail = "اتصال اینترنت برقرار نیست (%{host})",
    internet_speedtest_running = "در حال انجام تست سرعت سریع...",
    internet_speedtest_result = "دانلود: تقریباً %{mbps} مگابیت بر ثانیه",

    clients_title = "کلاینت‌های متصل",
    clients_none = "هیچ اجاره DHCP یافت نشد.",
    clients_kick_done = "%{name} قطع شد.",
    clients_kick_fail = "قطع کردن %{name} ممکن نشد.",

    wifi_title = "رادیوهای وای‌فای",
    wifi_enabled = "%{name}: روشن",
    wifi_disabled = "%{name}: خاموش",
    wifi_toggled = "وضعیت %{name} تغییر کرد. در حال بارگذاری مجدد وای‌فای...",

    packages_title = "پکیج‌ها",
    packages_installed_count = "%{count} پکیج نصب شده است.",
    packages_upgrade_available = "%{count} بروزرسانی موجود است.",
    packages_up_to_date = "سیستم به‌روز است.",

    passwall_status = "Passwall2: %{status}",
    singbox_status = "sing-box: %{status}",
    service_toggled = "وضعیت %{name} اکنون %{status} است.",

    backup_title = "پشتیبان‌گیری / بازیابی",
    backup_running = "در حال ساخت فایل پشتیبان از تنظیمات...",
    backup_done_caption = "پشتیبان تنظیمات روتر - %{date}",
    backup_failed = "پشتیبان‌گیری ناموفق بود. /logs را بررسی کنید.",
    restore_prompt = "فایل پشتیبان .tar.gz را برای بازیابی ارسال کنید.",
    restore_running = "در حال بازیابی تنظیمات...",
    restore_done = "بازیابی کامل شد. برای اعمال کامل تغییرات، ری‌استارت روتر لازم است.",
    restore_failed = "بازیابی ناموفق: %{reason}",
    restore_wrong_file = "این فایل یک پشتیبان معتبر ساخته‌شده توسط این بات نیست.",

    language_title = "زبان را انتخاب کنید",
    language_set = "زبان به %{name} تغییر کرد.",

    alert_cpu_high = "⚠️ بار پردازنده بالا: %{value}",
    alert_mem_high = "⚠️ مصرف حافظه بالا: %{percent}%%",
    alert_disk_high = "⚠️ مصرف فضای فلش بالا: %{percent}%%",
    alert_wan_down = "🔴 اتصال اینترنت قطع شد (%{host}).",
    alert_wan_recovered = "🟢 اتصال اینترنت برقرار شد (%{host}).",

    logs_title = "آخرین خطوط لاگ",
}
