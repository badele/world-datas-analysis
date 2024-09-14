#!/usr/bin/env just -f

set positional-arguments

envname:=`basename $(pwd)`
dockerimage:='badele/world-datas-analysis:latest'

# This help
@help:
    just -l --list-heading=$'{{ file_name(justfile()) }} commands:\n'

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

# Run duckdb cli on docker
@docker-duckdb:
    just docker-run "duckdb db/wda.duckdb"

# Run the wda docker image
@docker-run CMD="":
    docker run -it --rm -v $(pwd):/wda -w /wda {{ dockerimage }} {{ CMD }}

###############################################################################
# DB
###############################################################################

# Reset duckdb database
@db-reset:
    just docker-run "rm -f db/wda.duckdb"

###############################################################################
# dataset
###############################################################################

# Update datasets
@update:
    just docker-run ./importer/update.sh

# Import datasets to sqlite
@import:
    just docker-run ./importer/import.sh

# Lint the project
@lint:
    pre-commit run --all-files

# Update documentation
@doc-update FAKEFILENAME:
    just docker-run 'python3 ./updatedoc.py'
[private]
@perm-grafana:
    mkdir -p grafana-storage
    sudo chown -R 472 grafana
    sudo chown -R 472 dataset
    sudo chown -R 472 grafana-storage

[private]
@perm-user:
    mkdir -p grafana-storage
    sudo chown -R $(id -u) db
    sudo chown -R $(id -u) dataset
    sudo chown -R $(id -u) grafana
    sudo chown -R $(id -u) grafana-storage

# Start grafana
@start: perm-grafana
    docker compose up -d
    echo "go to http://localhost:3000"

# Stop grafana
@stop: perm-user
    docker compose stop

# Reset grafana storage
@reset:
    rm -rf grafana-storage

# Open browser to grafana page
@chart: start
    command -v xdg-open > /dev/null && xdg-open http://localhost:3000 || echo "goto to http://localhost:3000"

# Browse world datas
@browse:
    sqlitebrowser db/wda.sqlite

# Show installed packages
@packages:
    echo $PATH | tr ":" "\n" | grep -E "/nix/store" | sed -e "s/\/nix\/store\/[a-z0-9]\+\-//g" | sed -e "s/\/.*//g"
