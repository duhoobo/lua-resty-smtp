
local function send_mail()
    local mime = require("mime")
    local smtp = require("socket.smtp")
    local socket = require("socket")
    local ltn12 = require("ltn12")
    local config = require("config")


    print("Sending test mail...")

    local subject = "mail with attachment"
    local body = "mail plain text body"
    --local from = "mytest@myserver.com"
    --local to = {"bogdan@digitair.ro"}

    local attachment_content_type = "text/plain"
    local attachment_file_name = "README.md"
    local attachment = "You got me"

    local mesgt = { 
        headers = {
            from = config.from,
            to = table.concat(config.rcpt, ","),
            subject = "mail with attachment",
            ["x-mailer"] = "MyMailer",
        },

        body= {
            [1]= {body= body:gsub("%b<>", "")},
            [2]= {
                headers= {
                    ["content-type"]= attachment_content_type .. '; name="' .. attachment_file_name .. '"',
                    ["content-disposition"]= 'attachment; filename="' .. attachment_file_name .. '"',
                    ["content-transfer-encoding"]= "base64"
                },

                body= ltn12.source.chain(
                    ltn12.source.string(attachment), 
                    mime.encode("base64")
                )
            }
        }
    }

    local ret, err = smtp.send {
        from = config.from,
        rcpt = config.rcpt,
        user = config.user,
        password = config.password,
        server = config.server,
        --port = 465,
        domain = nil, 
        source = smtp.message(mesgt),
        create = socket.tcp,
        ssl = { enable = false, verify_cert = false }
    }

    if not ret then
        print(err)
    end
end

send_mail()
