local base = _G
local base64 = require("resty.smtp.base64")
local qpcore = require("resty.smtp.qp")

module("resty.smtp.misc")



function skip(amount, ...)
    return base.unpack({ ... }, amount + 1)
end


function newtry(atexit)
    return function(...) 
        local ret, err = base.select(1, ...), base.select(2, ...)

        if ret then return ...  end
        if base.type(atexit) == "function" then atexit() end

        base.error(err, 2)
        -- never be here
        return ret
    end
end


function except(func)
    return function(...) 
        local ok, ret = base.pcall(func, ...)

        if not ok then return nil, ret
        else return ret end
    end
end


try = newtry()


-- FIXME following mime-relative string operations are quite ineffient compared 
-- with original C version, maybe FFI can help?
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
    part1, ctx = qp.decode(ctx)

    if not chunk then
        if #part1 == 0 then return nil, nil
        else return part1, nil end
    end

    -- second part
    part2, ctx = qp.decode(ctx .. chunk)

    return part1 .. part2, ctx
end


-- line-wrap
--
function wrp()
    return
end

function qpwrp()
    return
end


-- dot
--
function dot(ctx, chunk, extra)
    local buffer = ""

    if not chunk then return nil, 2 end

    for i = 1, #chunk do
        local char = base.string.char(base.string.byte(chunk, i))

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
        local char = base.string.char(base.string.byte(chunk, i))

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

