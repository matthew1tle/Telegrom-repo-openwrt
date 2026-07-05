-- OpenWrt Telegram Bot Panel - Telegram HTTP Engine Interactivity Core
-- Production grade wrapping around POSIX curl pipelines

local helpers = require("core.helpers")
local logger = require("core.logger")

local M = {}

local API_BASE = "https://api.telegram.org/bot"
local token = ""
local allowed_ids = {}
local polling_timeout = 5

function M.init(bot_token, allowed_chat_ids, timeout)
    token = bot_token
    polling_timeout = tonumber(timeout) or 5
    
    allowed_ids = {}
    for id in string.gmatch(allowed_chat_ids or "", "([^,]+)") do
        local trimmed = id:gsub("^%s*(.-)%s*$", "%1")
        if trimmed ~= "" then
            allowed_ids[trimmed] = true
        end
    end
end

-- Verifies caller access matching configurations
function M.is_authorized(chat_id)
    if not chat_id then return false end
    if next(allowed_ids) == nil then return true end -- Open if undefined (failsafe setup fallback mode)
    return allowed_ids[tostring(chat_id)] == true
end

-- Standardized HTTP execution matrix wrapper
local function api_request(method, payload)
    if token == "" then
        logger.err("Telegram Engine call made prior to token initialization.")
        return nil
    end

    local url = string.format("%s%s/%s", API_BASE, token, method)
    local json_payload = helpers.json_encode(payload)
    
    -- Write payload out cleanly to bypass arg length boundary limits in shell pipelines
    local tmp_file = "/usr/share/owrt-tg-bot/tmp/tg_req.json"
    helpers.write_file(tmp_file, json_payload)
    
    local cmd = string.format(
        "curl -s -X POST -H 'Content-Type: application/json' -d @%s --connect-timeout 10 --max-time %d '%s'",
        tmp_file, polling_timeout + 10, url
    )
    
    local raw_response = helpers.exec(cmd)
    os.remove(tmp_file)
    
    local data = helpers.json_decode(raw_response)
    if not data.ok then
        logger.warn(string.format("Telegram API method %s returned failure: %s", method, raw_response))
    end
    return data
end

function M.get_updates(offset)
    local payload = {
        offset = offset,
        timeout = polling_timeout,
        allowed_updates = { "callback_query", "message" }
    }
    return api_request("getUpdates", payload)
end

function M.send_message(chat_id, text, reply_markup)
    local payload = {
        chat_id = chat_id,
        text = text,
        parse_mode = "Markdown",
        reply_markup = reply_markup and helpers.json_decode(reply_markup) or nil
    }
    return api_request("sendMessage", payload)
end

function M.edit_message(chat_id, message_id, text, reply_markup)
    local payload = {
        chat_id = chat_id,
        message_id = message_id,
        text = text,
        parse_mode = "Markdown",
        reply_markup = reply_markup and helpers.json_decode(reply_markup) or nil
    }
    return api_request("editMessageText", payload)
end

function M.answer_callback(callback_query_id, text, show_alert)
    local payload = {
        callback_query_id = callback_query_id,
        text = text or "",
        show_alert = show_alert or false
    }
    return api_request("answerCallbackQuery", payload)
end

return M