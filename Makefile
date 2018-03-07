ARGS = $(filter-out $@,$(MAKECMDGOALS))
MAKEFLAGS += --silent

list:
	sh -c "echo; $(MAKE) -p no_targets__ | awk -F':' '/^[a-zA-Z0-9][^\$$#\/\\t=]*:([^=]|$$)/ {split(\$$1,A,/ /);for(i in A)print A[i]}' | grep -v '__\$$' | grep -v 'Makefile'| sort"


#############################
# Setup
#############################

setup: new wait build

#############################
# Docker machine states
#############################

new:
	docker-compose pull
	docker-compose rm --force app
	docker-compose build --no-cache --pull
	docker-compose up -d --force-recreate

up:
	docker-compose up -d

start:
	docker-compose start

stop:
	docker-compose stop

down:
	docker-compose down --remove-orphans --volumes

state:
	docker-compose ps

rebuild:
	docker-compose stop
	docker-compose pull
	docker-compose rm --force app
	docker-compose build --no-cache --pull
	docker-compose up -d --force-recreate

#############################
# MySQL
#############################

mysql-backup:
	bash ./bin/backup.sh mysql

mysql-restore:
	bash ./bin/restore.sh mysql

mysql-rm:
	docker-compose rm mysql

#############################
# Solr
#############################

solr-backup:
	bash ./bin/backup.sh solr

solr-restore:
	bash ./bin/restore.sh solr

#############################
# General
#############################

backup:  mysql-backup  solr-backup
restore: mysql-restore solr-restore

build:
	bash bin/build.sh

clean:
	docker-compose down --remove-orphans --volumes
	test -d app/private && { rm -rf app/private; }
	test -d app/vendor && { rm -rf app/vendor; }
	test -d app/web && { rm -rf app/web; }
	test -d app/var && { rm -rf app/var; }

bash: shell

shell:
	docker-compose exec --user application app /bin/bash

root:
	docker-compose exec --user root app /bin/bash

wait:
	sleep 10

#############################
# TYPO3
#############################

cli:
	docker-compose run --rm --user application app cli $(ARGS)

scheduler:
	# TODO: remove the workaround "; (exit $?)" when https://github.com/docker/compose/issues/3379 has been fixed
	docker-compose exec --user application app /bin/bash -c '"$$WEB_DOCUMENT_ROOT"typo3/cli_dispatch.phpsh scheduler $(ARGS); (exit $$?)'

#############################
# Argument fix workaround
#############################
%:
	@:
