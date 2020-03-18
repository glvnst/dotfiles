LN = /bin/ln -s -v

COMPONENTS = .bash_profile .bash_logout .hushlogin .inputrc .lesskey .nanorc .vimrc .tmux.conf .zshrc

help:
	@echo "Use \"make install\" to link the files in this profile into your home directory"

install: $(COMPONENTS)
	@set -x; \
	for FILE in $(COMPONENTS); do \
	  $(LN) $$(pwd)/$$FILE $$HOME; \
	done; true
