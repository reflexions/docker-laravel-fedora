#!/usr/bin/env bash
set -x #echo on

# wait for database to open its port for connections
# http://unix.stackexchange.com/a/149053/47781
# this weird syntax is just bash being bash. It uses the DB_HOST value if set, localhost otherwise
# http://www.tldp.org/LDP/abs/html/parameter-substitution.html
db_driver=${DB_DRIVER-mysql}

[[ $db_driver = 'mysql' ]] && default_db_host="mysql" || default_db_host="postgres"
[[ $db_driver = 'mysql' ]] && default_db_port="3306" || default_db_port="5432"
db_host=${DB_HOST-$default_db_host}
db_port=${DB_PORT-$default_db_port}

echo "Waiting for DB to accept connections on $db_host/$db_port"
while ! timeout 1 bash -c "echo > /dev/tcp/$db_host/$db_port"; do echo "Waiting for database"; sleep 0.5; done
