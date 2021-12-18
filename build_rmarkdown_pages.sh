#!/usr/bin/env bash

# Init SQL database

# Update dataset summary
echo "Import and Export dataset summaries"
./importer/export.sh

echo "Generate readme.md"
Rscript build_rmarkdown_pages.R