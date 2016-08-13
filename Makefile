SHELL := /bin/bash

VENV=.venv
VENV_ACTIVATE=source $(VENV)/bin/activate
VM=kube-master-n01

assets-tls:
	./tls-setup.sh

start-cluster:
	vagrant up

stop-cluster:
	vagrant halt

reload-cluster:
	vagrant reload

destroy-cluster:
	vagrant destroy -f

ssh-cluster:
	vagrant ssh $(VM)

update-box:
	vagrant box update

clean: destroy-cluster
	rm -fr \
		$(VENV) \
		.assets \
		.vagrant
