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
# Check requirements
###############################################################################
@requirements-check:
    command -v curl >/dev/null 2>&1 || (echo "Please install curl" ; exit 1)
    command -v xz >/dev/null 2>&1 || (echo "Please install xz-utils" ; exit 1)
    command -v sudo >/dev/null 2>&1 || (echo "Please install sudo" ; exit 1)
    docker compose >/dev/null 2>&1 || (echo "Please install docker-compose-v2" ; exit 1)

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
@duckdb:
    duckdb db/wda.duckdb

# Run psql cli on dockers
@psql:
    PGPASSWORD=wda psql -h 127.0.0.1 -U wda -d wda

# Run the wda docker image
@docker-run CMD="": start
    docker run --net host -it --rm -v $(pwd):/wda -v $(pwd)/dataset:/var/lib/postgresql/data/dataset -w /wda {{ dockerimage }} {{ CMD }}

###############################################################################
# DB
###############################################################################

# Reset duckdb database
@db-reset:
    just docker-run "rm -f db/wda.duckdb"

###############################################################################
# dataset
###############################################################################

# Download datasets
@download: requirements-check
    just docker-run ./importer/download.sh

# Update datasets
@update: requirements-check
    just docker-run ./importer/update.sh

# Import datasets to sqlite
@import: requirements-check
    just docker-run ./importer/import.sh

# Lint the project
@lint: requirements-check
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
    echo "go to http://localhost:3000/dashboards"

# Stop grafana
@stop: perm-user
    docker compose stop

# Reset grafana storage
@reset:
    rm -rf grafana-storage

# Open browser to grafana page
@chart: start
    command -v xdg-open > /dev/null && xdg-open http://localhost:3000 || echo "goto to http://localhost:3000/dashboards"

# Open browser to pgadmin page
@pgadmin: start
    command -v xdg-open > /dev/null && xdg-open http://localhost:8080 || echo "goto to http://localhost:8080"

# Inspect parquet file
@parquet-inspect FILE:
    parquet-tools inspect {{ FILE }}

# Convert parquet file to CSV
@parquet-csv FILE:
    parquet-tools csv {{ FILE }}

# Show installed packages
@packages:
    echo $PATH | tr ":" "\n" | grep -E "/nix/store" | sed -e "s/\/nix\/store\/[a-z0-9]\+\-//g" | sed -e "s/\/.*//g"
