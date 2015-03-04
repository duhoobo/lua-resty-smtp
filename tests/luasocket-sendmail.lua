local mime = require("mime")
local smtp = require("socket.smtp")
local socket = require("socket")
local config = require("config")

function sendmail()
    mesgt = {
        headers= {
            subject = "subject",
            ["content-transfer-encoding"] = "quoted-printable",
            ["content-type"] = "text/plain; charset='utf-8'",
        },

        body= mime.qp("中文内容，HELLO WORLD."),
    }

    r, e = smtp.send {
        from= config.from,   -- e.g. "<user@sender.com>"
        rcpt= config.rcpt,   -- e.g. {"<user1@recipient.com>"}
        source= smtp.message(mesgt),
        server= config.server,  -- e.g. "mail.sender.com"
        domain= config.domain,  -- e.g. "user.sender.com"
        user= config.user,      -- e.g. "user@sender.com"
        password= config.password,  -- password for user
        create= socket.tcp,
        ssl= { enable= true, verify_cert= false },
    }

    print(r)
    print(e)
end


function main()
    sendmail()
end


main()

