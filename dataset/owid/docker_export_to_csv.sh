#!/usr/bin/env bash

wait_mysql () {
    while ! mysqladmin ping --silent; do
        echo "Wait mysqld ready"
        sleep 1
    done
}

echo "Export to CSV"
wait_mysql
mysql -D owid < /scripts/to_csv.sql
