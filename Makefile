
LUA_VERSION ?= 5.1
PREFIX ?=          /usr/local
LUA_INCLUDE_DIR ?= $(PREFIX)/include
LUA_LIB_DIR ?=     $(PREFIX)/share/lua/$(LUA_VERSION)
INSTALL ?= install


install:
	$(INSTALL) -d $(LUA_LIB_DIR)/resty
	$(INSTALL) -d $(LUA_LIB_DIR)/resty/smtp
	$(INSTALL) -m 644 lib/resty/*.lua $(LUA_LIB_DIR)/resty/
	$(INSTALL) -m 644 lib/resty/smtp/*.lua $(LUA_LIB_DIR)/resty/smtp/


