LUA ?= luajit
PLUGIN := ExternalRating.lrplugin
LR_PLUGIN_DIR := $(HOME)/Library/Application Support/Adobe/Lightroom/Modules

.PHONY: test lint install uninstall help

help:
	@echo "make test      Run the offline test suite (no Lightroom)"
	@echo "make lint      Byte-compile every Lua file to catch syntax errors"
	@echo "make install   Symlink the plugin into Lightroom's Modules folder"
	@echo "make uninstall Remove the symlink"

test:
	@$(LUA) tests/run.lua

# Syntax check. Catches Lua 5.3-only syntax that Lightroom's 5.1.4 would reject.
lint:
	@fail=0; \
	for f in $(PLUGIN)/*.lua tests/*.lua $(wildcard tests/stub/*.lua); do \
		$(LUA) -bl "$$f" >/dev/null 2>/tmp/er-lint.err || { \
			echo "SYNTAX ERROR in $$f"; cat /tmp/er-lint.err; fail=1; }; \
	done; \
	[ $$fail -eq 0 ] && echo "lint: all files parse under $$($(LUA) -v 2>&1 | head -1)"; \
	exit $$fail

install:
	@mkdir -p "$(LR_PLUGIN_DIR)"
	@rm -rf "$(LR_PLUGIN_DIR)/$(PLUGIN)"
	@ln -s "$(CURDIR)/$(PLUGIN)" "$(LR_PLUGIN_DIR)/$(PLUGIN)"
	@echo "Linked $(PLUGIN) into $(LR_PLUGIN_DIR)"
	@echo "Restart Lightroom Classic, then check Plug-in Manager."
	@echo "Note: Lightroom does not pick up files added to a plugin folder while running."

uninstall:
	@rm -rf "$(LR_PLUGIN_DIR)/$(PLUGIN)"
	@echo "Removed $(PLUGIN) from $(LR_PLUGIN_DIR)"
