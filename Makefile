function_files := $(wildcard bash_profile/functions/*/*.sh)

all: .bash_profile

.bash_profile: bash_profile/bash_profile_base.sh $(function_files) Makefile
	@echo "---> Building $@"
	sed -n '1,/# I-N-S-E-R-T - S-T-A-R-T/p' $< >$@
	( \
	  for func_path in $(function_files); do \
	    printf '\n'; \
	    sed -E "s|#!/bin/b?a?sh|# inserted from $${func_path}|" "$$func_path"; \
	    printf '\n'; \
	  done; \
	) >>$@
	sed -n '/# I-N-S-E-R-T - E-N-D/,//p' $< >>$@

