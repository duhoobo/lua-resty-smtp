local base = _G

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


