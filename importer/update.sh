#!/usr/bin/env bash

# Init database
duckdb db/wda.duckdb <./importer/init_duckdb.sql

# Export download data to CSV
/venv/bin/python ./importer/update.py
