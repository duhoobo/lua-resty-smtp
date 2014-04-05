package.path = "/home/duhoobo/prj/amateur/lua-resty-smtp/lib/?.lua;" .. package.path

local except = require("resty.except")




function func1()
    return "func1 OK"
end

function func2()
    return "func2 OK"
end

function func3()
    return nil, "func3 error"
end


local try = except.newtry(function() print "shit happened" end)

local entry = except.except(function(...)
                            print(#{...} .. " arguments received")

                            local ret = try(func1())
                            print(ret)

                            ret = try(func2())
                            print(ret)

                            ret = try(func3())
                            print(ret)
                        end)

local ret, err = entry(1, 2, 3)

print((ret and "true" or "false") .. " " .. (err or "nil"))
