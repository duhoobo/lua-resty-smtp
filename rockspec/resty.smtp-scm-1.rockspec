rockspec_format = "1.0"
package = "resty.smtp"
version = "scm-1"

description = {
    summary= "A smtp module for lua-nginx-module",
    detailed = [[]],
    license= "BSD",
    homepage= "http://ialloc.org",
    maintainer= "Hungpu DU <alecdu@gmail.com>",
}

dependencies = {
    "lua ~> 5.1"
}

-- contains information on how to fetch sources to build this rock.
source = {
    url= "git://github.com/duhoobo/lua-resty-smtp.git",
    branch= "master"
}

-- contains all information pertaining how to build this rock
build = {
    type = "builtin",
    modules =
    {
      ["resty.smtp"] = "lib/resty/smtp.lua",
      ["resty.smtp.base64"] = "lib/resty/smtp/base64.lua",
      ["resty.smtp.ltn12"] = "lib/resty/smtp/ltn12.lua",
      ["resty.smtp.mime-core"] = "lib/resty/smtp/mime-core.lua",
      ["resty.smtp.mime"] = "lib/resty/smtp/mime.lua",
      ["resty.smtp.misc"] = "lib/resty/smtp/misc.lua",
      ["resty.smtp.qp"] = "lib/resty/smtp/qp.lua",
      ["resty.smtp.tp"] = "lib/resty/smtp/tp.lua",
    },
}
