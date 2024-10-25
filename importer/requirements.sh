#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# Install required packages
if ! command -v curl &>/dev/null; then
	apt-get update && apt-get install -y git curl netcat-openbsd unzip python3 python3-venv python3-pip sqlite3
fi

# Install just package
if ! command -v just &>/dev/null; then
	curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin
fi

# Install postgresql
if ! command -v psql &>/dev/null; then
	apt-get update && apt-get install -y postgresql-client
fi

# Install duckdb
if ! command -v duckdb &>/dev/null; then
	curl -sL https://github.com/duckdb/duckdb/releases/download/v1.0.0/duckdb_cli-linux-amd64.zip -o /usr/local/bin/duckdb.zip
	unzip /usr/local/bin/duckdb.zip -d /usr/local/bin
	rm -f /usr/local/bin/duckdb.zip
fi

# Init env
if [ ! -d /venv ]; then
	python3 -m venv /venv
	/venv/bin/pip install -r requirements.txt
fi
