
package.path = "/home/duhoobo/prj/amateur/lua-resty-smtp/lib/?.lua;" .. package.path
local smtp = require("resty.smtp")
local mime = require("resty.smtp.mime")
local socket = require("socket")



function sendmail()
    from= "<wireless.alarm@baofeng.com>"

    rcpt= {
        "<15811046760@139.com>"
    }

    mesgt = {
        headers= {
            subject = "My first message",
            ["content-transfer-encoding"] = "BASE64",
            ["content-type"] = "text/plain; charset='utf-8'",
        },

        body= ltn12.source.chain(
            ltn12.source.string("中文内容"),
            mime.encode("base64"))
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

