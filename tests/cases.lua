package.path = "/home/duhoobo/prj/amateur/lua-resty-smtp/lib/?.lua;" .. package.path
local mime = require("mime")
local mine = require("resty.smtp.mime")


function test_dot()
    print "run test_dot ..."

    ea, eb = mime.dot(2, ".\r\nStuffing the message.\r\n.\r\n.")
    ca, cb = mine.dot(2, ".\r\nStuffing the message.\r\n.\r\n.")

    if ea == ca and eb == cb then print "OK"
    else print "failed" end
end

function test_eol()
    print "run test_eol ..."

    ea, eb = mime.eol(0, "abcd\nefg", "\r\n")
    ca, cb = mine.eol(0, "abcd\nefg", "\r\n")

    if ea == ca and eb == cb then print "OK"
    else print "failed" end
end

function test_b64_encode()
    print "run test_b64_encode ..."

    ea, eb = mime.b64("diego:password")
    ca, cb = mine.b64("diego:password")

    if ea == ca and eb == cb then print "OK"
    else print "failed" end

    ea, eb = mime.b64("")
    ca, cb = mine.b64("")

    if ea == ca and eb == cb then print "OK"
    else print "failed" end

    ea, eb = mime.b64("", "")
    ca, cb = mine.b64("", "")

    if ea == ca and eb == cb then print "OK"
    else print "failed" end
end

function test_b64_decode()
    print "run test_qp_encode ..."

    ea, eb = mime.unb64("ZGllZ286cGFzc3dvcmQ", "=")
    ca, cb = mine.unb64("ZGllZ286cGFzc3dvcmQ", "=")

    if ea == ca and eb == cb then print "OK"
    else print "failed" end
end


function test_qp_encode()
    print "run test_qp_encode ..."

    ea, eb = mime.qp("", "ma玢 xxxx")
    ca, cb = mine.qp("", "ma玢 xxxx")

    if ea == ca and eb == cb then print "OK"
    else print "failed" end
end

function test_qp_encode_pad()
    print "run test_qp_encode_pad ..."

    ea, eb = mime.qp("ma玢\r\n xxx\r")
    ca, cb = mine.qp("ma玢\r\n xxx\r")

    if ea == ca and eb == cb then print "OK"
    else print "failed" end
end


function test_qp_decode()
    print "run test_qp_decode ..."


    ea, eb = mime.unqp("ma\r\n =E7=E3\rxbd")
    ca, cb = mine.unqp("ma\r\n =E7=E3\rxbd")

    if ea == ca and eb == cb then print "OK"
    else print "failed" end
end


function test_wrp()
    print "run test_wrp ..."

    ea, eb = mime.wrp(4, "abcdefghijklmnopqrstuvwxzy", 4)
    ca, cb = mine.wrp(4, "abcdefghijklmnopqrstuvwxzy", 4)

    if ea == ca and eb == cb then print "OK"
    else print "failed" end

    ea, eb = mime.wrp(4, nil, 4)
    ca, cb = mine.wrp(4, nil, 4)

    if ea == ca and eb == cb then print "OK"
    else print "failed" end
end

function test_qpwrp()
    print "run test_qpwrp ..."

    ea, eb = mime.qpwrp(4, "ma=E7=E3=", 4)
    ca, cb = mine.qpwrp(4, "ma=E7=E3=", 4)

    if ea == ca and eb == cb then print "OK"
    else print "failed" end

    ea, eb = mime.qpwrp(4, nil, 4)
    ca, cb = mine.qpwrp(4, nil, 4)

    if ea == ca and eb == cb then print "OK"
    else print "failed" end
end

function test_ew()
    print "run test_ew ..."

    encoded_b = "=?utf-8?B?5rWL6K+VIEVuY29kZWQgV29yZA==?="

    extra = { charset= "utf-8", encoding= "B", initial= true}
    ca, cb = mine.ew("", "测试 Encoded Word", extra)
    ca2, cb = mine.ew(cb, nil, extra)

    if encoded_b == ca .. ca2 and cb == nil then print "OK"
    else print "failed" end

    ca, cb = mine.ew("测试 Encoded Word", nil, {})

    if encoded_b == ca and cb == nil then print "OK"
    else print "failed" end
end


function main() 
    test_dot()
    test_eol()
    test_b64_encode()
    test_b64_decode()
    test_qp_encode()
    test_qp_encode_pad()
    test_qp_decode()
    test_wrp()
    test_qpwrp()
    test_ew()
end


main()
