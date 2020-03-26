LN = /bin/ln -s -v

COMPONENTS := $(shell find . -mindepth 1 -maxdepth 1 -type f -name '.*')

help:
	@echo "Use \"make install\" to link the files in this profile into your home directory"

install: $(COMPONENTS)
	@for FILE in $(COMPONENTS); do \
	  $(LN) $$(pwd)/$$FILE $$HOME; \
	done; true
