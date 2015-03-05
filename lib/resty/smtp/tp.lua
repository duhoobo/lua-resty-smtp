-----------------------------------------------------------------------------
-- Unified SMTP/FTP subsystem
-- LuaSocket toolkit.
-- Author: Diego Nehab
-- RCS ID: $Id: tp.lua,v 1.22 2006/03/14 09:04:15 diego Exp $
-----------------------------------------------------------------------------
-- Author: duhoobo
-- ChangeLog: 
--  * 2014/04/06 03:47:15 - simplified for lua-module-module
-----------------------------------------------------------------------------


local base = _G
local string = require("string")

local ltn12 = require("resty.smtp.ltn12")
local misc = require("resty.smtp.misc")

module("resty.smtp.tp")


-- gets server reply (works for SMTP and FTP)
local function get_reply(c)
    local code, current, sep
    local line, err = c:receive("*l")
    local reply = line

    if err then return nil, err end

    code, sep = misc.skip(2, string.find(line, "^(%d%d%d)(.?)"))

    if not code then return nil, "invalid server reply" end
    if sep == "-" then -- reply is multiline
        repeat
            line, err = c:receive("*l")

            if err then return nil, err end

            current, sep = misc.skip(2, string.find(line, "^(%d%d%d)(.?)"))
            reply = reply .. "\n" .. line
        -- reply ends with same code
        until code == current and sep == " "
    end

    return code, reply
end


-- metatable for sock object
local metat = {__index= {}}


function metat.__index:expect(check)
    local code, reply = get_reply(self.c)

    if not code then return nil, reply end

    if base.type(check) ~= "function" then
        if base.type(check) == "table" then
            for i, v in base.ipairs(check) do
                if string.find(code, v) then
                    return base.tonumber(code), reply
                end
            end

            return nil, reply

        else -- string
            if string.find(code, check) then 
                return base.tonumber(code), reply
            else return nil, reply end
        end

    else return check(base.tonumber(code), reply) end
end


function metat.__index:command(cmd, arg)
    local request = cmd .. (arg and (" " .. arg) or "") .. "\r\n"
    return self.c:send(request)
end


function metat.__index:sink(snk, pat)
    local chunk, err = c:receive(pat)
    return snk(chunk, err)
end


function metat.__index:send(data)
    return self.c:send(data)
end


function metat.__index:receive(pat)
    return self.c:receive(pat)
end


function metat.__index:source(source, step)
    local sink = function(chunk, err)
        if chunk then return self:send(chunk)
        else return 1 end
    end

    return ltn12.pump.all(source, sink, step or ltn12.pump.step)
end


-- closes the underlying c
function metat.__index:close()
    self.c:close()
	return 1
end


-- connect with server and return c object
function connect(host, port, timeout, create, ssl)
    local c, e = create()
    if not c then return nil, e end

    c:settimeout(timeout)

    local r, e = c:connect(host, port)
    if not r then
        c:close()
        return nil, e
    end

    if ssl.enable then
        if not c.sslhandshake then
            c:close()
            return nil, "socket does not have ssl support"
        end

        local s, e = c:sslhandshake(nil, host, ssl.verify_cert)
        if not s then 
            c:close()
            return nil, "ssl handshake: " .. e
        end
    end

    return base.setmetatable({c= c}, metat)
end

