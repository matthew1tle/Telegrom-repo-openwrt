-- core/state.lua
-- Tiny in-memory state machine. main.lua runs as a single long-lived
-- process (per procd), so a plain Lua table is enough - no need for a
-- database. State is intentionally NOT persisted to disk: if the bot
-- restarts, chats just fall back to the main menu, which is safe.

local M = {
    chats = {},   -- chats[chat_id] = { awaiting = "restore_file", ... }
    alerts = {},  -- alerts[key] = true/false (last known "is firing" state)
}

function M.get(chat_id)
    M.chats[chat_id] = M.chats[chat_id] or {}
    return M.chats[chat_id]
end

function M.set(chat_id, key, value)
    local s = M.get(chat_id)
    s[key] = value
end

function M.clear(chat_id)
    M.chats[chat_id] = {}
end

function M.awaiting(chat_id)
    return M.get(chat_id).awaiting
end

function M.set_awaiting(chat_id, what)
    M.set(chat_id, "awaiting", what)
end

-- Alert de-duplication: alerts.lua uses this so it only sends a message
-- when a threshold transitions from "ok" to "firing", not on every loop.
function M.alert_is_firing(key)
    return M.alerts[key] == true
end

function M.set_alert_firing(key, firing)
    M.alerts[key] = firing
end

return M
