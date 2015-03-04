package.path = "/home/duhoobo/prj/amateur/lua-resty-smtp/lib/?.lua;" .. package.path
local ltn12 = require("resty.smtp.ltn12")
local mime = require("resty.smtp.mime")
local smtp = require("resty.smtp")
local socket = require("socket")
local config = require("config")


function sendmail()
    subject = "mail with attachment"
    body = "mail plain text body"

    attachment_content_type = "text/plain"
    attachment_file_name = "README.md"
    attachment = "You got me"

    mesgt = {
        headers= {
            from= config.from,
            to= table.concat(config.rcpt, ","),
            subject= mime.ew(subject, nil, {charset= "utf8"}),
            ["x-mailer"]= "MyMailer",
        },

        body= {
            [1]= {body= body:gsub("%b<>", "")},
            [2]= {
                headers= {
                    ["content-type"]= attachment_content_type .. '; name="' .. attachment_file_name .. '"',
                    ["content-disposition"]= 'attachment; filename="' .. attachment_file_name .. '"',
                    ["content-transfer-encoding"]= "base64",
                },

                body= ltn12.source.chain(ltn12.source.string(attachment), 
                                         mime.encode("base64"))
            }
        }
    }

    r, e = smtp.send {
        from= config.from,   -- e.g. "<user@sender.com>"
        rcpt= config.rcpt,   -- e.g. {"<user1@recipient.com>"}
        server= config.server,  -- e.g. {"mail.sender.com"}
        domain= config.domain,  -- e.g. "user.sender.com"
        user= config.user,      -- e.g. "user@sender.com"
        password= config.password,  -- password for user
        create= socket.tcp,
        source= smtp.message(mesgt),
        ssl= { enable= true, verify_cert= false },
    }

    print(r, e)
end


function main()
    sendmail()
end


main()

