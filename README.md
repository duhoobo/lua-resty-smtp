lua-resty-smtp
==============

I must be crazy trying to send mail with Nginx. 

TODO
----

* replace `os.date` with `ngx.localtime`
* timeout unit inconsistent
* clean namespace 

Purpose
-------


Features
--------


Extra filters
-------------


Installation
------------


Example
-------

    local config = require("config")
    local smtp = require("resty.smtp")
    local mime = require("resty.smtp.mime")
    local ltn12 = require("resty.smtp.ltn12")

    -- ...
    -- Suppose your mail data in table `args` and default settings 
    -- in table `config.mail`
    -- ...

    local mesgt = { 
        headers= {
            subject= mime.ew(args.subject or config.mail.SUBJECT, nil, 
                             { charset= "utf-8" }), 
            ["content-transfer-encoding"] = "BASE64",
            ["content-type"] = "text/plain; charset='utf-8'",
        },
    
        body= mime.b64(args.body)
    }   
    
    local ret, err = smtp.send {
        from= args.from or config.mail.FROM,
        rcpt= rcpts,
        user= args.user or config.mail.USER,
        password= args.password or config.mail.PASSWORD,
        server= args.server or config.mail.SERVER,
        domain= args.domain or config.mail.DOMAIN,
        source= smtp.message(mesgt),
    }   


Performance
-----------

Your SMTP server is the bottleneck. :)


Known Issues
------------


