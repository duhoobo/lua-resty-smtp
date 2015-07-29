-----------------------------------------------------------------------------
-- SMTP client support for the Lua language.
-- LuaSocket toolkit.
-- Author: Diego Nehab
-- RCS ID: $Id: smtp.lua,v 1.46 2007/03/12 04:08:40 diego Exp $
-----------------------------------------------------------------------------
-- Author: Hungpu DU
-- ChangeLog:
--  * 2014/04/06 03:50:15 - Modified for lua-nginx-module with pure Lua
-----------------------------------------------------------------------------


local base = _G
local coroutine = require("coroutine")
local string = require("string")
local math = require("math")
local os = require("os")

local mime = require("resty.smtp.mime")
local ltn12 = require("resty.smtp.ltn12")
local tp = require("resty.smtp.tp")
local misc = require("resty.smtp.misc")

module("resty.smtp")



VERSION = "resty.smtp 0.0.3"

-- timeout for connection
TIMEOUT = 6000
-- default server used to send e-mails
SERVER = "localhost"
-- default port
PORT = 25
-- domain used in HELO command and default sendmail
-- If we are under a CGI, try to get from environment
DOMAIN = "localhost"
-- default time zone (means we don"t know)
ZONE = "-0000"


local metat = { __index= {} }

function metat.__index:greet(domain)
    self.try(self.tp:expect("2.."))
    self.try(self.tp:command("EHLO", domain or DOMAIN))

    return misc.skip(1, self.try(self.tp:expect("2..")))
end


function metat.__index:mail(from)
    self.try(self.tp:command("MAIL", "FROM:" .. from))

    return self.try(self.tp:expect("2.."))
end


function metat.__index:rcpt(to)
    self.try(self.tp:command("RCPT", "TO:" .. to))

    return self.try(self.tp:expect("2.."))
end


function metat.__index:data(src, step)
    self.try(self.tp:command("DATA"))
    self.try(self.tp:expect("3.."))
    self.try(self.tp:source(src, step))
    self.try(self.tp:send("\r\n.\r\n"))

    return self.try(self.tp:expect("2.."))
end


function metat.__index:quit()
    self.try(self.tp:command("QUIT"))

    return self.try(self.tp:expect("2.."))
end


function metat.__index:close()
    return self.tp:close()
end


function metat.__index:login(user, password)
    self.try(self.tp:command("AUTH", "LOGIN"))
    self.try(self.tp:expect("3.."))
    self.try(self.tp:command(mime.b64(user)))
    self.try(self.tp:expect("3.."))
    self.try(self.tp:command(mime.b64(password)))

    return self.try(self.tp:expect("2.."))
end


function metat.__index:plain(user, password)
    local auth = "PLAIN " .. mime.b64("\0" .. user .. "\0" .. password)
    self.try(self.tp:command("AUTH", auth))
    return self.try(self.tp:expect("2.."))
end


function metat.__index:auth(user, password, ext)
    if not user or not password then return 1 end

    if string.find(ext, "AUTH[^\n]+LOGIN") then
        return self:login(user, password)

    elseif string.find(ext, "AUTH[^\n]+PLAIN") then
        return self:plain(user, password)

    else
        self.try(nil, "authentication not supported")
    end
end


-- send message or throw an exception
function metat.__index:send(mailt)
    self:mail(mailt.from)

    if base.type(mailt.rcpt) == "table" then
        for i, v in base.ipairs(mailt.rcpt) do
            self:rcpt(v)
        end

    else
        self:rcpt(mailt.rcpt)
    end

    self:data(ltn12.source.chain(mailt.source, mime.stuff()), mailt.step)
end


-- private methods
--
function open(server, port, timeout, create, ssl)
    local tp = misc.try(tp.connect(server, port, timeout, create, ssl))
    local session = base.setmetatable({tp= tp}, metat)

    -- make sure tp is closed if we get an exception
    session.try = misc.newtry(function()
                              session:close()
                          end)
    return session
end


-- convert headers to lowercase
local function lower_headers(headers)
    local lower = {}

    for i,v in base.pairs(headers or lower) do
        lower[string.lower(i)] = v
    end

    return lower
end


-- returns a hopefully unique mime boundary
local seqno = 0
local function newboundary()
    seqno = seqno + 1

    return string.format("%s%05d==%05u", os.date("%d%m%Y%H%M%S"),
                         math.random(0, 99999), seqno)
end


-- send_message forward declaration
local send_message

-- yield the headers all at once, it"s faster
local function send_headers(headers)
    local h = {}

    for k, v in base.pairs(headers) do
        base.table.insert(h, base.table.concat({k, v}, ": "))
    end
    base.table.insert(h, "\r\n")

    coroutine.yield(base.table.concat(h, "\r\n"))
end


-- yield multipart message body from a multipart message table
local function send_multipart(mesgt)
    -- make sure we have our boundary and send headers
    local bd = newboundary()
    local headers = lower_headers(mesgt.headers or {})

    headers["content-type"] = headers["content-type"] or "multipart/mixed"
    headers["content-type"] = headers["content-type"] ..
        '; boundary="' ..  bd .. '"'

    send_headers(headers)

    -- send preamble
    if mesgt.body.preamble then
        coroutine.yield(mesgt.body.preamble)
        coroutine.yield("\r\n")
    end

    -- send each part separated by a boundary
    for i, m in base.ipairs(mesgt.body) do
        coroutine.yield("\r\n--" .. bd .. "\r\n")
        send_message(m)
    end

    -- send last boundary
    coroutine.yield("\r\n--" .. bd .. "--\r\n\r\n")

    -- send epilogue
    if mesgt.body.epilogue then
        coroutine.yield(mesgt.body.epilogue)
        coroutine.yield("\r\n")
    end
end


-- yield message body from a source
local function send_source(mesgt)
    -- make sure we have a content-type
    local headers = lower_headers(mesgt.headers or {})

    headers["content-type"] = headers["content-type"] or
        'text/plain; charset="iso-8859-1"'

    send_headers(headers)

    -- send body from source
    while true do
        local chunk, err = mesgt.body()
        if err then coroutine.yield(nil, err)
        elseif chunk then coroutine.yield(chunk)
        else break end
    end
end


-- yield message body from a string
local function send_string(mesgt)
    -- make sure we have a content-type
    local headers = lower_headers(mesgt.headers or {})

    headers["content-type"] = headers["content-type"] or
        'text/plain; charset="iso-8859-1"'

    send_headers(headers)

    -- send body from string
    coroutine.yield(mesgt.body)
end


-- message source
function send_message(mesgt)
    if base.type(mesgt.body) == "table" then
        send_multipart(mesgt)

    elseif base.type(mesgt.body) == "function" then
        send_source(mesgt)

    else
        send_string(mesgt)
    end
end


-- set defaul headers
local function adjust_headers(mesgt)
    -- to eliminate duplication for following headers
    local lower = lower_headers(mesgt.headers)

    lower["date"] = lower["date"] or
        os.date("!%a, %d %b %Y %H:%M:%S ") .. (mesgt.zone or ZONE)
    lower["x-mailer"] = lower["x-mailer"] or VERSION
    -- this can"t be overriden
    lower["mime-version"] = "1.0"

    return lower
end


function message(mesgt)
    mesgt.headers = adjust_headers(mesgt)

    -- create and return message source
    local co = coroutine.create(function() send_message(mesgt) end)

    return function()
        local ok, a, b = coroutine.resume(co)
        if ok then return a, b
        else return nil, a end
    end
end


-- public methods
--
send = misc.except(function(mailt)
    local session = open(mailt.server or SERVER, mailt.port or PORT,
                         mailt.timeout or TIMEOUT,
                         mailt.create or base.ngx.socket.tcp,
                         mailt.ssl or {enable= false, verify_cert= false})

    local ext = session:greet(mailt.domain)

    session:auth(mailt.user, mailt.password, ext)
    session:send(mailt)
    session:quit()

    return session:close()
end)


