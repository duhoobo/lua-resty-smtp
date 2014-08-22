
LUA_VERSION=5.1

LUA_DIR=/usr/local/openresty

# for Lua modules
LUA_SHAREDIR=$(LUA_DIR)/lualib

INSTALL=install

.PHONY: all

all:
	@echo "Nothing to compile, just 'make install' ..."

install:
	$(INSTALL) -d $(LUA_SHAREDIR)/resty
	$(INSTALL) -d $(LUA_SHAREDIR)/resty/smtp
	$(INSTALL) -m 644 lib/resty/*.lua $(LUA_SHAREDIR)/resty/
	$(INSTALL) -m 644 lib/resty/smtp/*.lua $(LUA_SHAREDIR)/resty/smtp/

