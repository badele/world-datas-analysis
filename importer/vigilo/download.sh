#!/usr/bin/env bash

IMPORT="downloaded/vigilo"
rm -rf "$IMPORT"
mkdir -p "$IMPORT" db

#Download categories and scopes
curl -s "https://vigilo-bf7f2.firebaseio.com/categorieslist.json" | jq '.' >"$IMPORT/categories.json"
curl -s "https://vigilo-bf7f2.firebaseio.com/citylist.json" | jq '[to_entries[] | {name: .key} + .value]' >"$IMPORT/scopes.json"
jq -r '.[] | select ( .prod == true) | .scope + ";" + .api_path' "$IMPORT/scopes.json" >"$IMPORT/instances.csv"

# Download observations
while IFS=';' read -r scope url; do
	echo "Download $scope at $url"
	curl -sL "$url/get_scope.php?scope=${scope}" | jq 'del(.cities)' >"$IMPORT/instance_tmp_${scope}.json"
	curl -sL "$url/get_issues.php?scope=${scope}&format=json" | jq ".[] |=  (. += {\"scope\": \"$scope\"})" >"$IMPORT/observation_tmp_${scope}.json"
done <"$IMPORT/instances.csv"

# join scope and instance info
for f in $IMPORT/observation_tmp_*.json; do
	# retrive scope from filename
	scope=$(echo $f | sed -E 's/.*observation_tmp_(.*)\.json/\1/')
	jq ". +{\"scope\": \"$scope\"}" "$IMPORT/instance_tmp_$scope.json" >"$IMPORT/instance_scope_${scope}.json"
	jq "map(. +{\"scope\": \"$scope\"})" "$IMPORT/observation_tmp_$scope.json" >"$IMPORT/observation_scope_${scope}.json"
done

# Merge json
jq -s '.' $IMPORT/instance_scope_*.json >"$IMPORT/instances.json"
jq -s 'add' $IMPORT/observation_scope_*.json >"$IMPORT/observations.json"

# Delete temporary file
rm -f $IMPORT/instances.csv
# rm -f $IMPORT/instance_*.json
# rm -f $IMPORT/observations_*.json

#sqlite3 -bail db/world-datas-analysis.db <importer/vigilo/import.sql

# python importer/vigilo/download.py
# Rscript importer/vigilo/download.R
