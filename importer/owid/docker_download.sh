#!/usr/bin/env bash

wait_mysql () {
    while ! mysqladmin ping --silent; do
        echo "Wait mysqld ready"
        sleep 1
    done
}


wait_mysql

apt-get update
apt-get install -y curl 
#sqlite3 python3-pip
#pip3 install mysql-to-sqlite3

# Download owid databases
wait_mysql
mysql -e "CREATE DATABASE owid;"

if [ ! -f /downloaded/owid_metadata.sql.gz ]; then
    curl -Lo /downloaded/owid_metadata.sql.gz https://files.ourworldindata.org/owid_metadata.sql.gz
fi

echo "Import owid metadata"
wait_mysql
gunzip < /downloaded/owid_metadata.sql.gz | mysql -D owid

if [ ! -f /downloaded/owid_chartdata.sql.gz ]; then
curl -Lo /downloaded/owid_chartdata.sql.gz https://files.ourworldindata.org/owid_chartdata.sql.gz
fi

echo "Import owid datas"
wait_mysql
gunzip < /downloaded/owid_chartdata.sql.gz | mysql -D owid

# echo "Export to CSV"
# wait_mysql
# mysql -D owid < /scripts/to_csv.sql
