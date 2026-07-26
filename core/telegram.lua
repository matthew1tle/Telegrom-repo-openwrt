-- core/telegram.lua
-- Talks to the Telegram Bot API over POSIX curl, since that's already a
-- dependency (installed by install.sh) and avoids pulling in a full HTTP
-- client library just for JSON POSTs.

local helpers = require("core.helpers")
local logger = require("core.logger")

local M = {
    base_url = nil,
    file_base_url = nil,
}

function M.init(bot_token)
    M.base_url = "https://api.telegram.org/bot" .. bot_token
    M.file_base_url = "https://api.telegram.org/file/bot" .. bot_token
end

-- Shell-quote a string for safe use inside single quotes in sh.
local function shq(s)
    return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

-- POST JSON to a Telegram method and return the decoded response table.
local function call(method, params)
    if not M.base_url then
        logger.error("telegram.call before init(): " .. method)
        return nil, "not initialized"
    end
    local body = helpers.json_encode(params or {})
    if not body then
        return nil, "json encode failed"
    end

    local cmd = string.format(
        "curl -s -m 20 -H %s -X POST -d %s %s",
        shq("Content-Type: application/json"),
        shq(body),
        shq(M.base_url .. "/" .. method)
    )

    local out, ok = helpers.shell(cmd)
    if not ok or out == "" then
        logger.warn("telegram api call failed: " .. method)
        return nil, "curl failed"
    end

    local decoded, err = helpers.json_decode(out)
    if not decoded then
        logger.warn("telegram api decode failed: " .. method .. " " .. tostring(err))
        return nil, err
    end
    if decoded.ok == false then
        logger.warn("telegram api error: " .. method .. " -> " .. tostring(decoded.description))
        return nil, decoded.description
    end
    return decoded.result
end

function M.get_updates(offset, timeout_sec)
    return call("getUpdates", {
        offset = offset,
        timeout = timeout_sec or 25,
        allowed_updates = { "message", "callback_query" },
    })
end

function M.send_message(chat_id, text, keyboard)
    return call("sendMessage", {
        chat_id = chat_id,
        text = text,
        parse_mode = "HTML",
        reply_markup = keyboard,
    })
end

function M.edit_message(chat_id, message_id, text, keyboard)
    return call("editMessageText", {
        chat_id = chat_id,
        message_id = message_id,
        text = text,
        parse_mode = "HTML",
        reply_markup = keyboard,
    })
end

function M.answer_callback(callback_id, text)
    return call("answerCallbackQuery", {
        callback_query_id = callback_id,
        text = text,
        show_alert = false,
    })
end

-- Send a local file as a document. Uses multipart curl (-F), so this one
-- bypasses the JSON `call()` helper.
function M.send_document(chat_id, filepath, caption)
    if not M.base_url then return nil, "not initialized" end
    local cmd = string.format(
        "curl -s -m 60 -F %s -F %s -F document=@%s %s",
        shq("chat_id=" .. chat_id),
        shq("caption=" .. (caption or "")),
        shq(filepath),
        shq(M.base_url .. "/sendDocument")
    )
    local out, ok = helpers.shell(cmd)
    if not ok then return nil, "curl failed" end
    return helpers.json_decode(out)
end

-- Resolve a Telegram file_id to a local path (used for /restore uploads).
function M.download_file(file_id, dest_path)
    local info = call("getFile", { file_id = file_id })
    if not info or not info.file_path then
        return false, "could not resolve file"
    end
    local url = M.file_base_url .. "/" .. info.file_path
    local cmd = string.format("curl -s -m 60 -o %s %s", shq(dest_path), shq(url))
    local _, ok = helpers.shell(cmd)
    return ok, ok and nil or "download failed"
end

function M.set_webhook(url)
    return call("setWebhook", { url = url })
end

function M.delete_webhook()
    return call("deleteWebhook", {})
end

return M
