local base = _G
local string = require("string")
local base64 = require("resty.smtp.base64")
local qpcore = require("resty.smtp.qp")

module("resty.smtp.mime")



-- FIXME following mime-relative string operations are quite inefficient 
-- compared with original C version, maybe FFI can help?
--
-- base64
--
function b64(ctx, chunk, extra)
    local part1, part2

    if not ctx then return nil, nil end

    -- remaining data from last round
    part1, ctx = base64.encode(ctx)

    if not chunk then 
        part1 = part1 .. base64.pad(ctx)

        if #part1 == 0 then return nil, nil
        else return part1, nil end
    end

    -- second part
    part2, ctx = base64.encode(ctx .. chunk)

    return part1 .. part2, ctx
end

function unb64(ctx, chunk, extra)
    local part1, part2

    if not ctx then return nil, nil end

    -- remaining data from last round
    part1, ctx = base64.decode(ctx)

    if not chunk then
        if #part1 == 0 then return nil, nil
        else return part1, nil end
    end

    -- second part
    part2, ctx = base64.decode(ctx .. chunk)

    return part1 .. part2, ctx
end


-- quoted-printable
--
function qp(ctx, chunk, extra)
    local part1, part2, marker

    if not ctx then return nil, nil end

    marker = extra or "\r\n"
    part1, ctx = qpcore.encode(ctx, marker)

    if not chunk then
        part1 = part1 .. qpcore.pad(ctx)

        if #part1 == 0 then return nil, nil
        else return part1, nil end
    end

    -- second part
    part2, ctx = qpcore.encode(ctx .. chunk, marker)

    return part1 .. part2, ctx
end

function unqp(ctx, chunk, extra)
    local part1, part2

    if not ctx then return nil, nil end

    -- remaining data from last round
    part1, ctx = qpcore.decode(ctx)

    if not chunk then
        if #part1 == 0 then return nil, nil
        else return part1, nil end
    end

    -- second part
    part2, ctx = qpcore.decode(ctx .. chunk)

    return part1 .. part2, ctx
end


-- line-wrap
--
function wrp(ctx, chunk, extra)
    -- `ctx` shows how many more bytes current line can still hold
    -- before reach the limit `length`
    local buffer, length = "", extra or 76

    if not chunk then 
        -- last line already has some chars except \r\n
        if ctx < length then return buffer .. "\r\n", length
        else return nil, length end
    end

    for i = 1, #chunk do
        local char = chunk:sub(i, i)

        if char == '\r' then
            -- take it as part of "\r\n"
        elseif char == '\n' then
            buffer, ctx = buffer .. "\r\n", length
        else
            if ctx <= 0 then -- hit the limit
                buffer, ctx = buffer .. "\r\n", length
            end

            buffer, ctx = buffer .. char, ctx - 1
        end
    end

    return buffer, ctx
end

function qpwrp(ctx, chunk, extra)
    -- `ctx` shows how many more bytes current line can still hold
    -- before reach the limit `length`
    local buffer, length = "", extra or 76

    if not chunk then 
        -- last line already has some chars except \r\n
        if ctx < length then return buffer .. "=\r\n", length
        else return nil, length end

    end

    for i = 1, #chunk do
        local char = chunk:sub(i, i)

        if char == '\r' then
            -- take it as part of "\r\n"
        elseif char == '\n' then
            buffer, ctx = buffer .. "\r\n", length
        elseif char == '=' then
            if ctx <= 3 then
                buffer, ctx = buffer .. "=\r\n", length
            end
            
            buffer, ctx = buffer .. char, ctx - 1

        else
            if ctx <= 1 then
                buffer, ctx = buffer .. "=\r\n", length
            end

            buffer, ctx = buffer .. char, ctx - 1
        end
    end

    return buffer, ctx
end


-- encoded word
--
function ew(ctx, chunk, extra)
    local part0, part1, part2 = "", "", ""
    local c, e, f

    base.assert(base.type(extra) == "table")

    c = extra.charset or "utf-8"
    e = extra.encoding or "B"
    m = (e == "Q") and qpcore or base64

    -- TODO not support Q-encoding yet
    base.assert(e == "B")

    if extra.initial == nil or extra.initial then
        part0 = string.format("=?%s?%s?", c, e)
        extra.initial = false
    end

    part1, ctx = m.qencode(ctx, true)

    if not chunk then
        part1 = part1 .. m.qpad(ctx, true)
        return part0 .. part1 .. "?=", nil
    end

    part2, ctx = m.qencode(ctx .. chunk, true)

    return part0 .. part1 .. part2, ctx
end

--
-- extra - the charset to converted to
function unew(ctx, chunk, extra)
    -- TODO
    -- This one needs a little more work, because we have to decode 
    -- `chunk` with both specified encoding and charset on the fly.
    --
end


-- dot
--
function dot(ctx, chunk, extra)
    local buffer = ""

    if not chunk then return nil, 2 end

    for i = 1, #chunk do
        local char = string.char(string.byte(chunk, i))

        buffer = buffer .. char

        if char == '\r' then
            ctx = 1
        elseif char == '\n' then
            ctx = (ctx == 1) and 2 or 0
        elseif char == "." then
            if ctx == 2 then buffer = buffer .. "." end
            ctx = 0
        else 
            ctx = 0 
        end
    end

    return buffer, ctx
end


-- eol
--
function eol(ctx, chunk, marker)
    local buffer = ""

    if not chunk then return nil, 0 end

    local eolcandidate = function(char) 
        return (char == '\r') or (char == '\n')
    end

    for i = 1, #chunk do
        local char = string.char(string.byte(chunk, i))

        if eolcandidate(char) then
            if eolcandidate(ctx) then
                if char == ctx then buffer = buffer .. marker end
                ctx = 0
            else 
                buffer = buffer .. marker
                ctx = char
            end

        else
            buffer = buffer .. char
            ctx = 0
        end
    end

    return buffer, ctx
end

