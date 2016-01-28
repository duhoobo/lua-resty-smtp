-----------------------------------------------------------------------------
-- MIME support for the Lua language.
-- Author: Diego Nehab
-- Conforming to RFCs 2045-2049
-- RCS ID: $Id: mime.lua,v 1.29 2007/06/11 23:44:54 diego Exp $
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Declare module and import dependencies
-----------------------------------------------------------------------------
local base = _G
local io = require("io")
local string = require("string")

require("resty.smtp.mime-core")
local ltn12 = require("resty.smtp.ltn12")

module("resty.smtp.mime")



-- encode, decode and wrap algorithm tables
encodet = {}
decodet = {}
wrapt = {}

-- creates a function that chooses a filter by name from a given table
local function choose(table)
    return function(name, opt1, opt2)
        if base.type(name) ~= "string" then
            name, opt1, opt2 = "default", name, opt1
        end
        local f = table[name or "nil"]
        if not f then 
            base.error("unknown key (" .. base.tostring(name) .. ")", 3)
        else return f(opt1, opt2) end
    end
end

-- define the encoding filters
encodet['base64'] = function()
    return ltn12.filter.cycle(b64, "")
end

encodet['quoted-printable'] = function(mode)
    return ltn12.filter.cycle(qp, "",
        (mode == "binary") and "=0D=0A" or "\r\n")
end

encodet['encoded-word'] = function(charset, encoding)
    return ltn12.filter.cycle(ew, "", 
        { charset= charset or "utf-8", encoding= encoding or "B" })
end

-- define the decoding filters
decodet['base64'] = function()
    return ltn12.filter.cycle(unb64, "")
end

decodet['quoted-printable'] = function()
    return ltn12.filter.cycle(unqp, "")
end

decodet['encoded-word'] = function(encoding)
    return ltn12.filter.cycle(unew, "",
        { encoding= encoding or "Q" })
end

local function format(chunk)
    if chunk then
        if chunk == "" then return "''"
        else return string.len(chunk) end
    else return "nil" end
end

-- define the line-wrap filters
wrapt['text'] = function(length)
    length = length or 76
    return ltn12.filter.cycle(wrp, length, length)
end
wrapt['base64'] = wrapt['text']
wrapt['default'] = wrapt['text']

wrapt['quoted-printable'] = function()
    return ltn12.filter.cycle(qpwrp, 76, 76)
end

-- function that choose the encoding, decoding or wrap algorithm
encode = choose(encodet)
decode = choose(decodet)
wrap = choose(wrapt)

-- define the end-of-line normalization filter
function normalize(marker)
    if not marker then marker = '\r\n' end
    return ltn12.filter.cycle(eol, 0, marker)
end

-- high level stuffing filter
function stuff()
    return ltn12.filter.cycle(dot, 2)
end

