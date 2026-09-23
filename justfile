#!/usr/bin/env just -f

set positional-arguments

envname:=`basename $(pwd)`
dockerimage:='badele/world-datas-analysis:latest'
dockerimage_push:='badele/world-datas-analysis:latest'
observabledir:='observable'

# This help
@help:
    just -l --list-heading=$'{{ file_name(justfile()) }} commands:\n'

###############################################################################
# pre-commit
###############################################################################

# Build precommit image and configure git hooks path
precommit-install:
    docker compose build precommit
    git config core.hooksPath .githooks

# Run pre-commit on all files via Docker
@precommit-check:
    docker compose run --rm precommit pre-commit run --all-files

# Update pre-commit hooks revisions via Docker
@precommit-update:
    docker compose run --rm precommit pre-commit autoupdate

# Check requirements
@requirements-check:
    command -v curl >/dev/null 2>&1 || (echo "Please install curl" ; exit 1)
    command -v xz >/dev/null 2>&1 || (echo "Please install xz-utils" ; exit 1)
    command -v sudo >/dev/null 2>&1 || (echo "Please install sudo" ; exit 1)
    docker compose >/dev/null 2>&1 || (echo "Please install docker-compose-v2" ; exit 1)

###############################################################################
# Docker
###############################################################################

# Build all docker images
@docker-build:
    docker build -q -t {{ dockerimage }} .
    docker compose build precommit

# Push the wda docker image to docker hub
@docker-push:
    docker push {{ dockerimage_push }}

# Run duckdb cli on docker
@duckdb:
    duckdb db/wda.duckdb

# Run psql cli on dockers
@psql:
    PGPASSWORD=wda psql -h 127.0.0.1 -U wda -d wda

# Run the wda docker image
@docker-run CMD="": docker-build
    docker run --net host -i --rm -e DATAS_LIST="$DATAS_LIST" -v $(pwd):/wda -v $(pwd)/dataset:/var/lib/postgresql/data/dataset -w /wda {{ dockerimage }} {{ CMD }}

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

# Run Python unit tests
@test: docker-build
    docker run --rm -t -v $(pwd):/wda -w /wda {{ dockerimage }} \
        /venv/bin/pytest tests -v --color=yes

# Lint the project
@lint: requirements-check
    pre-commit run --all-files

# Update documentation
@doc-update FAKEFILENAME:
    DATAS_LIST="" just docker-run 'python3 ./updatedoc.py'

# Start all services
@start:
    just docker-build
    docker compose up --build -d
    echo ""
    echo "Services disponibles :"
    echo "  http://localhost:9300  →  grafana       (admin/admin)"
    echo "  http://localhost:9400  →  observable    (dev, hot-reload)"
    echo "  http://localhost:9500  →  observable    (production, nginx)"
    echo "  http://localhost:9600  →  pgAdmin"

    echo ""

# Clear cache
@observable-clear-cache:
    rm -rf observable/src/.observablehq/cache/ observable/dist/

# Build the Observable static site (production, with npm ci)
@observable-build:
    just observable-clear-cache
    docker compose run --rm observable-build
    docker compose up -d observable

# Build the Observable site into observable/dist for static hosting
@observable-pages-build:
    just observable-clear-cache
    docker run --rm --network host \
        -v "$(pwd)/observable:/app" \
        -w /app \
        -e PGHOST=127.0.0.1 \
        -e PGPORT=5432 \
        -e PGDATABASE=wda \
        -e PGUSER=wda \
        -e PGPASSWORD=wda \
        docker.io/library/node:22-slim \
        sh -ec 'npm ci && npm run build'

# Prepare the database and build the site for GitHub Pages
@pages-build:
    docker compose up -d psql
    DATAS_LIST="geonames,vigilo" just import
    just observable-pages-build

# Start Observable dev server with hot reload (port 3000)
@observable-dev:
    docker compose up observable-dev

# Install/update Observable npm dependencies
@observable-install:
    docker run --rm \
        -v "$(pwd)/{{ observabledir }}:/app" \
        -w /app \
        docker.io/library/node:22-alpine \
        npm install

# Remove Observable dist volume and rebuild
@observable-reset:
    docker compose stop observable >/dev/null 2>&1 || true
    docker compose rm -sf observable-build >/dev/null 2>&1 || true
    docker volume rm world-datas-analysis_observable-dist >/dev/null 2>&1 || true
    echo "Observable build removed; rebuild with 'just observable-build'"

# Stop all services
@stop:
    docker compose stop

# Open browser to grafana page
@chart: start
    command -v xdg-open > /dev/null && xdg-open http://localhost:9300 || echo "goto to http://localhost:9300/dashboards"

# Open browser to observable page
@observable: start
    command -v xdg-open > /dev/null && xdg-open http://localhost:9400 || echo "goto to http://localhost:9400"

# Open browser to pgadmin page
@pgadmin: start
    command -v xdg-open > /dev/null && xdg-open http://localhost:9600 || echo "goto to http://localhost:9600"

# Inspect parquet file
@parquet-inspect FILE:
    parquet-tools inspect {{ FILE }}

# Convert parquet file to CSV
@parquet-csv FILE:
    parquet-tools csv {{ FILE }}

# Show installed packages
@packages:
    echo $PATH | tr ":" "\n" | grep -E "/nix/store" | sed -e "s/\/nix\/store\/[a-z0-9]\+\-//g" | sed -e "s/\/.*//g"
