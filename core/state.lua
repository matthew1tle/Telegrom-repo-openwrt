-- OpenWrt Telegram Bot Panel - Central State Machine Engine
-- Tracks interactive user sessions, navigation menus, and target operational contexts

local helpers = require("core.helpers")

local M = {}

local STATE_BASE_DIR = "/var/run/owrt-tg-bot"

-- Ensure tracking directory structure is active
local function get_user_file(chat_id)
    return string.format("%s/user_%s.json", STATE_BASE_DIR, tostring(chat_id))
end

-- Get current runtime structural states for a given session ID
function M.get(chat_id)
    local path = get_user_file(chat_id)
    local raw = helpers.read_file(path)
    if not raw or raw == "" then
        -- Default Initial Global Object State Matrix
        return {
            menu = "main",
            context = {},
            pending_action = nil,
            last_message_id = nil
        }
    end
    return helpers.json_decode(raw)
end

-- Persist atomic session structural metadata mutation
function M.set(chat_id, state_obj)
    local path = get_user_file(chat_id)
    local encoded = helpers.json_encode(state_obj)
    return helpers.write_file(path, encoded)
end

-- Safely clear context and structural states
function M.clear(chat_id)
    local path = get_user_file(chat_id)
    os.remove(path)
end

-- Mutate single field within context maps safely
function M.update_context(chat_id, key, value)
    local state = M.get(chat_id)
    state.context = state.context or {}
    state.context[key] = value
    M.set(chat_id, state)
end

-- Transition navigation states directly helper
function M.transition_to(chat_id, target_menu, clear_context)
    local state = M.get(chat_id)
    state.menu = target_menu
    state.pending_action = nil
    if clear_context then
        state.context = {}
    end
    M.set(chat_id, state)
    return state
end

return M