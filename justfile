#!/usr/bin/env just -f

set positional-arguments

envname:=`basename $(pwd)`
dockerimage:='badele/world-datas-analysis:latest'

# This help
@help:
    just -lu --list-heading=$'{{ file_name(justfile()) }} commands:\n'

###############################################################################
# pre-commit
###############################################################################

# Setup pre-commit
precommit-install:
    #!/usr/bin/env bash
    test ! -f .git/hooks/pre-commit && pre-commit install || true

# Update pre-commit
@precommit-update:
    pre-commit autoupdate

# precommit check
@precommit-check:
    pre-commit run --all-files

###############################################################################
# Docker
###############################################################################

# Build the wda docker image
@docker-build:
    docker build -t {{ dockerimage }} .

# Push the wda docker image to docker hub
@docker-push:
    docker push {{ dockerimage }}

# RUn the wda docker image
@docker-run:
    docker run -it --rm -v $(pwd):/wda -w /wda {{ dockerimage }}



# Lint the project
@lint:
    pre-commit run --all-files

# Update documentation
@doc-update FAKEFILENAME:
    ./updatedoc.ts

[private]
@grafana-perm:
    mkdir -p grafana
    sudo chown -R 472 grafana

[private]
@user-perm:
    mkdir -p grafana
    sudo chown -R $(id -u) grafana

# Start grafana
@start: user-perm restore grafana-perm
    docker compose up -d
    echo "go to http://localhost:3000"

# Stop grafana
@stop:
    docker compose stop

# Show grafana logs
@logs:
    docker compose logs

# Backup grafana configuration
# @backup: stop user-perm
#     mkdir -p backup
#     tar -czvf backup/grafana-$(date +%Y%m%d).tar.gz --exclude grafana/plugins grafana
#     sqlite3 grafana/grafana.db .dump > backup/grafana.sql

# Dump grafana database
@dump: stop user-perm
    mkdir -p backup
    sqlite3 grafana/grafana.db .dump > backup/grafana.sql

# Restore grafana database
restore: stop user-perm
    #!/usr/bin/env bash
    if [ -f backup/grafana.sql ]; then
        echo "Restore Grafana configuration"
        rm -f grafana/grafana.db
        sqlite3 grafana/grafana.db <  backup/grafana.sql
    fi

# Import datas
@import:
    ./importer/import.sh

# Browse world datas
@browse:
    sqlitebrowser db/wda.sqlite

# Show installed packages
@packages:
    echo $PATH | tr ":" "\n" | grep -E "/nix/store" | sed -e "s/\/nix\/store\/[a-z0-9]\+\-//g" | sed -e "s/\/.*//g"
