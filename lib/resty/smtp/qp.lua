local base = _G
local math = require("math")
local table = require("table")
local string = require("string")

module("resty.smtp.qp")



--[[

[Quoted-Printable Rules](http://en.wikipedia.org/wiki/Quoted-printable)

* All characters except printable ASCII characters or end of line characters 
  must be encoded.

* All printable ASCII characters (decimal 33-126) may be represented by 
  themselves, except "=" (decimal 61)

* ASCII tab (decimal 9) and space (decimal 32) may be represented by themselves,
  except if these characters would appear at the end of the encoded line. In
  that case, they would need to be escaped as "=09" or "=20", or be followed
  by a "=" (soft line break)

* If the data being encoded contains meaningful line breaks, they must be 
  encoded as an ASCII CRLF sequence. Conversely, if byte value 13 and 10 have
  meanings other than end of line (in media types, for example), they must
  be encoded as "=0D" and "=0A" respectively.

* Lines of Quoted-Printable encoded data must not be longer than 76 characters.
  To satisfy this requirement without altering the encoded text, 
  _soft line breaks_ consists of an "=" at the end of an encoded line, and does
  not appear as a line break in the decoded text.


Encoded-Word - A slightly modified version of Quoted-Printable used in message
headers.

--]]

local QP_PLAIN = 0
local QP_QUOTE = 1
local QP_IF_LAST = 3
local QP_BYTE_CR = 13 -- '\r'
local QP_BYTE_LF = 10 -- '\n'


qpte = {
--  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15
    1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 1, 1, 1, 2, 1, 1, --  0  -  15
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, --  16 -  31
    3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, --  32 -  47
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, --  48 -  63
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, --  64 -  79
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, --  80 -  95
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, --  96 - 111
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, -- 112 - 127
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, -- 128 - 143
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, -- 144 - 159
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, -- 160 - 175
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, -- 176 - 191
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, -- 192 - 207
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, -- 208 - 223
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, -- 224 - 239
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, -- 240 - 255
}



qptd = {
}


local HEXBASE = "0123456789ABCDEF"

local quote = function(byte)
    local f, s = math.floor(byte/16) + 1, math.fmod(byte, 16) + 1
    return table.concat({ '=', HEXBASE:sub(f, f), HEXBASE:sub(s, s) })
end


function pad(chunk)
    local buffer, byte = "", 0

    for i = 1, #chunk do
        byte = base.string.byte(chunk, i)

        if qpte[byte + 1] == QP_PLAIN then
            buffer = buffer .. base.string.char(byte)
        else
            buffer = buffer .. quote(byte)
        end
    end

    -- soft break
    if #buffer > 0 then buffer = buffer .. "=\r\n" end

    return buffer
end


function encode(chunk, marker)
    local atom, buffer = {}, ""

    for i = 1, #chunk do
        table.insert(atom, base.string.byte(chunk, i))

        repeat
            local shift = 1

            if atom[1] == QP_BYTE_CR then
                if #atom < 2 then -- need more
                    break
                elseif atom[2] == QP_BYTE_LF then 
                    buffer, shift = buffer .. marker, 2
                else 
                    buffer = buffer .. quote(atom[1])
                end

            elseif qpte[atom[1] + 1] == QP_IF_LAST then
                if #atom < 3 then -- need more
                    break    
                elseif atom[2] == QP_BYTE_CR and atom[3] == QP_BYTE_LF then
                    buffer, shift = buffer .. quote(atom[1]) .. marker, 3
                else -- space not in the end
                    buffer = buffer .. string.char(atom[1])
                end

            elseif qpte[atom[1] + 1] == QP_QUOTE then
                buffer = buffer .. quote(atom[1])
            else -- printable char
                buffer = buffer .. string.char(atom[1])
            end

            -- shift out used chars
            for i = 1, 3 do atom[i] = atom[i + shift] end

        until #atom == 0

    end

    for i = 1, 3 do 
        atom[i] = atom[i] and string.char(atom[i]) or "" 
    end

    return buffer, table.concat(atom, "")
end


function decode(chunk, marker)
end


