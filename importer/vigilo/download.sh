#!/usr/bin/env bash

IMPORT="downloaded/vigilo"
rm -rf "$IMPORT"
mkdir -p "$IMPORT" db

#Download categories and scopes
curl -s "https://vigilo-bf7f2.firebaseio.com/categorieslist.json" >"$IMPORT/categories.json"
curl -s "https://vigilo-bf7f2.firebaseio.com/citylist.json" | jq '[to_entries[] | {name: .key} + .value]' >"$IMPORT/scopes.json"
jq -r '.[] | select ( .prod == true) | .scope + ";" + .api_path' "$IMPORT/scopes.json" >"$IMPORT/instances.csv"

# Download observations
while IFS=';' read -r scope url; do
	echo "Download $scope at $url"
	curl -sL "$url/get_scope.php?scope=${scope}" | jq 'del(.cities)' >"$IMPORT/instance_${scope}.json"
	# curl -sL "$url/get_issues.php?scope=${scope}&format=json" | jq ".[] |=  (. += {\"scope\": \"$scope\"})" >"$IMPORT/observation_tmp_${scope}.json"
	curl -sL "$url/get_issues.php?scope=${scope}&format=json" >"$IMPORT/observation_${scope}.json"
done <"$IMPORT/instances.csv"

# Remove bad json format
while IFS=';' read -r scope url; do
	if [ "$(file -b "$IMPORT/instance_${scope}.json")" != "JSON text data" ]; then
		echo "Delete bad $scope JSON file"
		rm -f "$IMPORT/instance_${scope}.json"
		rm -f "$IMPORT/observation_${scope}.json"
	fi
done <"$IMPORT/instances.csv"
