BASENAME ?= tilde
PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
MANDIR ?= $(PREFIX)/share/man

install:
	@echo Installing the executable to $(BINDIR)
	@mkdir -p $(BINDIR)
	@cp -f $(BASENAME) $(BINDIR)/$(BASENAME)
	@chmod 755 $(BINDIR)/$(BASENAME)
	@echo Installing the manual page to $(MANDIR)/man1
	@mkdir -p $(MANDIR)/man1
	@cp -f $(BASENAME).1 $(MANDIR)/man1/$(BASENAME).1
	@chmod 644 $(MANDIR)/man1/$(BASENAME).1

uninstall:
	@echo Removing the executable from $(BINDIR)
	@rm -f $(BINDIR)/$(BASENAME)
	@echo Removing the manual page from $(MANDIR)/man1
	@rm -f $(BINDIR)/man1/$(BASENAME).1

.PHONY: install uninstall

