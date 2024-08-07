FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && apt-get install -y git curl unzip python3 python3-venv python3-pip sqlite3

# Install duckdb
RUN curl -sL https://github.com/duckdb/duckdb/releases/download/v1.0.0/duckdb_cli-linux-amd64.zip -o /usr/local/bin/duckdb.zip
RUN unzip /usr/local/bin/duckdb.zip -d /usr/local/bin
RUN rm -f /usr/local/bin/duckdb.zipA

COPY requirements.txt /tmp/requirements.txt

# Init env
RUN python3 -m venv /venv
RUN /venv/bin/pip install -r /tmp/requirements.txt
