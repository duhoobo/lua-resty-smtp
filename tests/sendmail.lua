
package.path = "/home/duhoobo/prj/amateur/lua-resty-smtp/lib/?.lua;" .. package.path
local misc = require("resty.smtp.misc")
local ltn12 = require("resty.smtp.ltn12")
local mime = require("resty.smtp.mime")
local smtp = require("resty.smtp")
local socket = require("socket")



function sendmail()
    from= "<wireless.alarm@baofeng.com>"

    rcpt= {
        "<15811046760@139.com>"
    }

    mesgt = {
        headers= {
            subject = misc.ew("中文标题", nil, {}),
            ["content-transfer-encoding"] = "quoted-printable",
            ["content-type"] = "text/plain; charset='utf-8'",
        },

        body= misc.qp("中文内容，HELLO WORLD. Fuck you mother fucker"),
    }

    r, e = smtp.send {
        from= from,
        rcpt= rcpt,
        source= smtp.message(mesgt),
        server= "mail.baofeng.com",
        domain= "wireless-alarm",
        user= "wireless.alarm@baofeng.com",
        password= "qwe123",
        create= socket.tcp,
    }

    print(r)
    print(e)
end


function main()
    sendmail()
end


main()

