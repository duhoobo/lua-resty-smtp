OPENRESTY_PREFIX=/usr/local/openresty

LUA_VERSION := 5.1
PREFIX ?=	/usr/local
LUA_INCLUDE_DIR ?= $(PREFIX)/include
LUA_LIB_DIR ?= $(PREFIX)/lib/lua/$(LUA_VERSION)
INSTALL=install

.PHONY: all install test

all:
	@echo "Nothing to compile, just 'make install' ..."

install:
	$(INSTALL) -d $(LUA_SHAREDIR)/resty
	$(INSTALL) -d $(LUA_SHAREDIR)/resty/smtp
	$(INSTALL) -m 644 lib/resty/*.lua $(LUA_SHAREDIR)/resty/
	$(INSTALL) -m 644 lib/resty/smtp/*.lua $(LUA_SHAREDIR)/resty/smtp/

test: all
	PATH=$(OPENRESTY_PREFIX)/nginx/sbin:$$PATH prove -r t
