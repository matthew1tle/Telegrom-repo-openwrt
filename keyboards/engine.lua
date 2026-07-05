-- OpenWrt Telegram Bot Panel - Inline Keyboard Matrix Builder
-- Optimized to generate valid Telegram API InlineKeyboardMarkup JSON structures

local helpers = require("core.helpers")
local lang = require("lang.en")

local M = {}

-- Instantiates a clean, blank keyboard workspace matrix
function M.create()
    return { inline_keyboard = {} }
end

-- Appends an interactive row with arbitrary amounts of inline action keys
function M.add_row(kb, buttons)
    local row = {}
    for _, btn in ipairs(buttons) do
        table.insert(row, {
            text = btn.text,
            callback_data = btn.callback_data
        })
    end
    table.insert(kb.inline_keyboard, row)
    return kb
end

-- Injects standard contextual control elements (Back to main dashboard / Refresh current context map)
function M.add_control_row(kb, back_target, refresh_target)
    local controls = {}
    if back_target then
        table.insert(controls, { text = lang.get("back"), callback_data = back_target })
    end
    if refresh_target then
        table.insert(controls, { text = lang.get("refresh"), callback_data = refresh_target })
    end
    if #controls > 0 then
        M.add_row(kb, controls)
    end
    return kb
end

-- Builds structural confirmation interfaces before running irreversible or system critical functions
function M.build_confirmation(target_action, cancel_action)
    local kb = M.create()
    M.add_row(kb, {
        { text = lang.get("confirm_yes"), callback_data = target_action },
        { text = lang.get("confirm_no"), callback_data = cancel_action }
    })
    return kb
end

-- Export completed object directly to JSON string format
function M.export(kb)
    return helpers.json_encode(kb)
end

return M