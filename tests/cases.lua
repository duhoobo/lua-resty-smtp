package.path = "/home/duhoobo/prj/amateur/lua-resty-smtp/lib/?.lua;" .. package.path
local mime = require("mime")
local misc = require("resty.smtp.misc")


function test_dot()
    -- dot
    print(mime.dot(2, ".\r\nStuffing the message.\r\n.\r\n."))
    print "---"
    print(misc.dot(2, ".\r\nStuffing the message.\r\n.\r\n."))
end

function test_eol()
    dos = "abcd\nefg"
    print(#mime.eol(0, dos, "\r\n"))
    print(#misc.eol(0, dos, "\r\n"))
end

function test_b64_encode()
    print(mime.b64("diego:password"))
    a, b = mime.b64("")
    print("[" .. (a or "nil") .. "]")
    print("[" .. (b or "nil") .. "]")

    a, b = mime.b64("", "")
    print("[" .. (a or "nil") .. "]")
    print("[" .. (b or "nil") .. "]")
    --
    print(misc.b64("diego:password"))
    a, b = misc.b64("")
    print("[" .. (a or "nil") .. "]")
    print("[" .. (b or "nil") .. "]")

    a, b = misc.b64("", "")
    print("[" .. (a or "nil") .. "]")
    print("[" .. (b or "nil") .. "]")
end

function test_b64_decode()
    print(mime.unb64("ZGllZ286cGFzc3dvcmQ", "="))
    print(misc.unb64("ZGllZ286cGFzc3dvcmQ", "="))
end


function test_qp_encode()
    print "run test_qp_encode ..."

    ea, eb = mime.qp("", "ma玢 xxxx")
    ca, cb = misc.qp("", "ma玢 xxxx")

    if ea == ca and eb == cb then print "passed"
    else print "failed" end
end

function test_qp_encode_pad()
    print "run test_qp_encode_pad ..."

    ea, eb = mime.qp("ma玢\r\n xxx\r")
    ca, cb = misc.qp("ma玢\r\n xxx\r")

    if ea == ca and eb == cb then print "passed"
    else print "failed" end
end


function test_qp_decode()
    print "run test_qp_decode ..."


    ea, eb = mime.unqp("ma\r\n =E7=E3\rxbd")
    ca, cb = misc.unqp("ma\r\n =E7=E3\rxbd")

    if ea == ca and eb == cb then print "passed"
    else print "failed" end
end


function test_wrp()
    print "run test_wrp ..."

    ea, eb = mime.wrp(4, "abcdefghijklmnopqrstuvwxzy", 4)
    ca, cb = misc.wrp(4, "abcdefghijklmnopqrstuvwxzy", 4)

    if ea == ca and eb == cb then print "passed"
    else print "failed" end
end


function main() 
    test_wrp()
end


main()
