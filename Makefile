BASENAME ?= tilde
PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
MANDIR ?= $(PREFIX)/share/man

install:
	@set -eu; \
	mkdir -p "$(BINDIR)" "$(MANDIR)/man1"; \
	install -m 0755 "$(BASENAME)" "$(BINDIR)/.$(BASENAME).new"; \
	mv -f "$(BINDIR)/.$(BASENAME).new" "$(BINDIR)/$(BASENAME)"; \
	install -m 0644 "$(BASENAME).1" "$(MANDIR)/man1/.$(BASENAME).1.new"; \
	mv -f "$(MANDIR)/man1/.$(BASENAME).1.new" "$(MANDIR)/man1/$(BASENAME).1"

uninstall:
	@rm -f "$(BINDIR)/$(BASENAME)" "$(MANDIR)/man1/$(BASENAME).1"

test:
	@sh tests/smoke.sh

.PHONY: install uninstall test
