rockspec_format = "1.0"
package = "resty.smtp"
version = "0.0.3-1"



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
    file= "lua-resty-smtp"
}

-- contains all information pertaining how to build this rock
build = {
    type= "make",
}
