local function send_mail()
    local smtp = require("resty.smtp")
    local mime = require("resty.smtp.mime")
    local ltn12 = require("resty.smtp.ltn12")

    ngx.log(ngx.ERR, "Sending test mail...")

    local subject = "mail with attachment"
    local body = "mail plain text body"
    local from = "mytest@myserver.com"
    local to = {"bogdan@digitair.ro"}

    local attachment_content_type = "text/plain"
    local attachment_file_name = "README.md"
    local attachment = "You got me"

    local mesgt = { 
        headers = {
            from = "MyTest <"..from..">",
            to = table.concat(to, ","),
            subject = mime.ew(subject, nil, {charset= "utf8"}),
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
        from = from,
        rcpt = to,
        user = '<user>',
        password = '<pass>',
        server = '<server>',
        port = 465,
        domain = nil,
        source = smtp.message(mesgt),
        ssl = { enable = true, verify_cert = false }
    }

    if err then
        ngx.log(ngx.ERR, err)
    end
end

ngx.thread.spawn(send_mail)

ngx.say("OK")
ngx.eof()