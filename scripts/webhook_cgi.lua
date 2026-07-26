#!/usr/bin/env lua
-- scripts/webhook_cgi.lua
--
-- Registered with uhttpd (see init.d/owrt-tg-bot) so Telegram's webhook
-- POST lands here. All this does is read the request body and drop it as
-- a JSON file into the queue directory core/main.lua polls - it does NOT
-- talk to modules/router directly, so the CGI process (short-lived, one
-- per request) never needs to load the whole bot.

local QUEUE_DIR = "/tmp/owrt-tg-bot-webhook-queue"

local function read_body()
    local len = tonumber(os.getenv("CONTENT_LENGTH") or "0") or 0
    if len <= 0 then return "" end
    return io.read(len) or ""
end

local function write_queue_file(body)
    os.execute("mkdir -p " .. QUEUE_DIR)
    local name = string.format("%s/%d-%d.json", QUEUE_DIR, os.time(), math.random(100000, 999999))
    local f = io.open(name, "w")
    if f then
        f:write(body)
        f:close()
    end
end

math.randomseed(os.time())

local body = read_body()
if body ~= "" then
    write_queue_file(body)
end

-- Telegram only needs a fast 200 OK; the actual processing happens async
-- in core/main.lua's webhook loop.
io.write("Status: 200 OK\r\n")
io.write("Content-Type: text/plain\r\n\r\n")
io.write("ok")
