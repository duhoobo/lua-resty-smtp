package.path = "/home/duhoobo/prj/amateur/lua-resty-smtp/lib/?.lua;" .. package.path
local mime = require("mime")
local misc = require("resty.misc")


print(mime.dot(2, ".\r\nStuffing the message.\r\n.\r\n."))
print "---"
print(misc.dot(2, ".\r\nStuffing the message.\r\n.\r\n."))

dos = "abcd\nefg"

print(#mime.eol(0, dos, "\r\n"))
print(#misc.eol(0, dos, "\r\n"))

print(#mime.b64())
print(#misc.b64())
