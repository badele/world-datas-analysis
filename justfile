#!/usr/bin/env just -f

set positional-arguments
set dotenv-load

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
[group('precommit')]
precommit-install:
    docker compose build precommit
    git config core.hooksPath .githooks

# Run pre-commit on all files via Docker
[group('precommit')]
@precommit-check:
    docker compose run --rm precommit pre-commit run --all-files

# Update pre-commit hooks revisions via Docker
[group('precommit')]
@precommit-update:
    docker compose run --rm precommit pre-commit autoupdate

###############################################################################
# Docker
###############################################################################

# Build all docker images
[group('docker')]
@docker-build:
    docker build -q -t {{ dockerimage }} .
    docker compose build precommit

# Show files sent to Docker build context (respects .dockerignore)
[group('docker')]
docker-show-context-files:
    #!/usr/bin/env bash
    excludes=()
    while IFS= read -r pattern; do
        [[ "$pattern" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${pattern// }" ]] && continue
        excludes+=("!" "-path" "./$pattern" "!" "-path" "./$pattern/*")
    done < .dockerignore
    find . -type f "${excludes[@]}" | sed 's|^\./||' | sort

# Show Docker build context size by first-level entry (respects .dockerignore)
[group('docker')]
docker-show-context-size:
    #!/usr/bin/env bash
    declare -A excluded
    while IFS= read -r pattern; do
        [[ "$pattern" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${pattern// }" ]] && continue
        excluded["${pattern%%/*}"]=1
    done < .dockerignore
    find . -maxdepth 1 -mindepth 1 | sed 's|^\./||' | sort | while read -r entry; do
        [[ -z "${excluded[$entry]}" ]] && du -sh "$entry"
    done | sort -h

# Push the wda docker image to docker hub
[group('docker')]
@docker-push:
    docker push {{ dockerimage_push }}

# Run the wda docker image
[group('docker')]
@docker-run CMD="": docker-build
    docker run --net host -i --rm -e DATAS_LIST="$DATAS_LIST" -v $(pwd):/wda -v $(pwd)/dataset:/var/lib/postgresql/data/dataset -w /wda {{ dockerimage }} {{ CMD }}

###############################################################################
# DB
###############################################################################

# Run duckdb cli
[group('db')]
@duckdb:
    duckdb db/wda.duckdb

# kill duckdb container
@duckdb-kill:
    docker kill $(docker ps -q --filter ancestor=badele/world-datas-analysis:latest)

# Run psql cli
[group('db')]
@psql:
    PGPASSWORD=wda psql -h 127.0.0.1 -U wda -d wda

# Reset duckdb database
[group('db')]
@db-reset:
    just docker-run "rm -f db/wda.duckdb"

###############################################################################
# Dataset
###############################################################################

# Check requirements
[group('dataset')]
@requirements-check:
    command -v curl >/dev/null 2>&1 || (echo "Please install curl" ; exit 1)
    command -v xz >/dev/null 2>&1 || (echo "Please install xz-utils" ; exit 1)
    command -v sudo >/dev/null 2>&1 || (echo "Please install sudo" ; exit 1)
    docker compose >/dev/null 2>&1 || (echo "Please install docker-compose-v2" ; exit 1)

# Download datasets
[group('dataset')]
@download: requirements-check
    just docker-run ./importer/download.sh

# Update datasets
[group('dataset')]
@update: requirements-check
    just docker-run ./importer/update.sh

# Generate observable parquets (e.g: DATAS_LIST=sirene just observable-export)
[group('dataset')]
@observable-export: requirements-check
    just docker-run ./importer/observable_export.sh

# Generate etab prefix parquets from existing APE parquets (no full pipeline needed)
[group('dataset')]
@sirene-etab-parquets:
    bash importer/sirene/generate_etab_parquets.sh


# Delete GitHub Releases for the given datasets (release + tag)
# Usage: DATAS_LIST="sirene,nafrev2" just release-delete
[group('dataset')]
release-delete:
    #!/usr/bin/env bash
    datasets="${DATAS_LIST:-}"
    datasets="${datasets//,/ }"
    if [ -z "$datasets" ]; then echo "DATAS_LIST is empty"; exit 1; fi
    for dataset in $datasets; do
        tag="dataset-${dataset}"
        echo "[release-delete] deleting release ${tag}..."
        gh release delete "$tag" --cleanup-tag --yes 2>/dev/null && echo "[release-delete] done" || echo "[release-delete] ${tag} not found"
    done

# Upload parquets to GitHub Releases (transparency, versioning)
# Usage: DATAS_LIST="sirene,geonames" just release-github
[group('dataset')]
@release-github: requirements-check
    ./importer/release_github.sh

# Upload parquets to Cloudflare R2 (CORS-enabled, for GitHub Pages)
# Requires: CF_ACCOUNT_ID, CF_R2_ACCESS_KEY_ID, CF_R2_SECRET_ACCESS_KEY
# Usage: DATAS_LIST="sirene,geonames" just release-cloudflare
[group('dataset')]
@release-cloudflare: requirements-check
    ./importer/release_cloudflare.sh

# Upload parquets to both GitHub Releases and Cloudflare R2
# Usage: DATAS_LIST="sirene,geonames" just release
[group('dataset')]
@release: requirements-check
    just release-github
    just release-cloudflare


# Download parquets from GitHub Releases and restore directory structure
# Usage: DATAS_LIST="sirene,geonames" just release-download
[group('dataset')]
@release-download: requirements-check
    ./importer/release_download.sh

# Import datasets (downloads parquets from GitHub Releases if not already present)
# PostgreSQL import en pause — décommenter "just docker-run" ci-dessous pour réactiver
[group('dataset')]
@import: requirements-check
    ./importer/release_download.sh
    # just docker-run ./importer/import.sh

# Run Python unit tests
[group('dataset')]
@test: docker-build
    docker run --rm -t -v $(pwd):/wda -w /wda {{ dockerimage }} \
        /venv/bin/pytest tests -v --color=yes

# Lint the project
[group('dataset')]
@lint: requirements-check
    pre-commit run --all-files

# Update documentation
[group('dataset')]
@doc-update FAKEFILENAME:
    DATAS_LIST="" just docker-run 'python3 ./updatedoc.py'

###############################################################################
# Parquet
###############################################################################

# Inspect parquet file
[group('parquet')]
@parquet-inspect FILE:
    parquet-tools inspect {{ FILE }}

# Convert parquet file to CSV
[group('parquet')]
@parquet-csv FILE:
    parquet-tools csv {{ FILE }}

###############################################################################
# Observable
###############################################################################

# Install/update Observable npm dependencies
[group('observable')]
@observable-install:
    docker run --rm \
        -v "$(pwd)/{{ observabledir }}:/app" \
        -w /app \
        docker.io/library/node:22-alpine \
        npm install

# Clear Observable cache and dist
[group('observable')]
@observable-clear-cache:
    rm -rf observable/src/.observablehq/cache/ observable/dist/

# Start Observable dev server with hot reload (port 3000)
[group('observable')]
@observable-dev:
    docker compose up observable-dev

# Build the Observable static site (production, with npm ci)
[group('observable')]
@observable-build:
    just observable-clear-cache
    docker compose run --rm observable-build
    docker compose up -d observable

# Build the Observable site into observable/dist for static hosting
[group('observable')]
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
        -e DATAS_LIST="${DATAS_LIST:-}" \
        -e WDA_PUBLIC_DATASET_URL="${WDA_PUBLIC_DATASET_URL:-}" \
        docker.io/library/node:22-slim \
        sh -ec 'npm ci && npm run build'

# Prepare the database and build the site for GitHub Pages
[group('observable')]
@pages-build:
    docker compose up -d psql
    DATAS_LIST="geonames,vigilo,nafrev2,sirene" just import
    DATAS_LIST="vigilo,nafrev2,sirene" just observable-pages-build

# Build the production site and serve it locally on port 8080 (mirrors CI)
[group('observable')]
@observable-prod:
    DATAS_LIST="${DATAS_LIST:-vigilo,nafrev2,sirene}" just observable-pages-build
    docker run --rm -p 8080:80 \
        -v "$(pwd)/observable/dist:/usr/share/nginx/html:ro" \
        -v "$(pwd)/dataset:/usr/share/nginx/html/dataset:ro" \
        -v "$(pwd)/observable/nginx.conf:/etc/nginx/conf.d/default.conf:ro" \
        docker.io/library/nginx:1.27-alpine

# Remove Observable dist volume and rebuild
[group('observable')]
@observable-reset:
    docker compose stop observable >/dev/null 2>&1 || true
    docker compose rm -sf observable-build >/dev/null 2>&1 || true
    docker volume rm world-datas-analysis_observable-dist >/dev/null 2>&1 || true
    echo "Observable build removed; rebuild with 'just observable-build'"

###############################################################################
# Services
###############################################################################

# Start all services
[group('services')]
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

# Stop all services
[group('services')]
@stop:
    docker compose stop

# Open browser to grafana page
[group('services')]
@chart: start
    command -v xdg-open > /dev/null && xdg-open http://localhost:9300 || echo "goto to http://localhost:9300/dashboards"

# Open browser to observable page
[group('services')]
@observable: start
    command -v xdg-open > /dev/null && xdg-open http://localhost:9400 || echo "goto to http://localhost:9400"

# Open browser to pgadmin page
[group('services')]
@pgadmin: start
    command -v xdg-open > /dev/null && xdg-open http://localhost:9600 || echo "goto to http://localhost:9600"

###############################################################################
# Utils
###############################################################################

# Show installed nix packages
[group('utils')]
@packages:
    echo $PATH | tr ":" "\n" | grep -E "/nix/store" | sed -e "s/\/nix\/store\/[a-z0-9]\+\-//g" | sed -e "s/\/.*//g"
