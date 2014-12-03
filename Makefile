# $Id: Makefile,v 2.4 2011/09/20 03:38:40 bburke Exp $
CP_EXEC = /bin/cp -p
RCP_EXEC = /usr/bin/scp -p -r
CHMOD_EXEC = /bin/chmod
REMOTE_HOSTS = arm.local
COMPONENTS = .bash_profile .bash_logout .hushlogin .inputrc .lesskey .nanorc .vimrc .tmux.conf .zshrc

help:
	@echo "Use \"make install\" to send this profile to remote hosts and install it locally."

install: install-local install-remote

# $(COMPONENTS): .%: DOT_%
# 	@echo "==> Readying $@"
# 	$(CP_EXEC) $< $@
# 	$(CHMOD_EXEC) a-rwx,u+rw $@

install-local: $(COMPONENTS)
	@echo "==> Installing into your current home directory."
	$(CP_EXEC) $(COMPONENTS) $$HOME/

install-remote: $(COMPONENTS)
	@for HOST in $(REMOTE_HOSTS); do \
		echo "==> Installing for remote account $$HOST"; \
		$(RCP_EXEC) $(COMPONENTS) "$${HOST}:"; \
	done

clean:
	@echo "==> Cleaning the local directory"
	rm -f $(COMPONENTS)
