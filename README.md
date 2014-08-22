lua-resty-smtp
==============

I must be crazy trying to send mail with Nginx. 

TODO
----


Purpose
-------


Features
--------

* SSL connection supported (lua-nginx-lua >= v0.9.11 needed)


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

* Only work with LuaJIT 2.x now, because the codebase relies on `pcall`
  massively and lua-nginx-module does not work well with standard Lua 5.1 VM 
  under this situation. See [Known Issues](http://wiki.nginx.org/HttpLuaModule#Lua_Coroutine_Yielding.2FResuming)


