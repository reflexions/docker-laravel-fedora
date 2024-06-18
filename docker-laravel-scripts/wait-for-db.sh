#!/usr/bin/env bash
script_dir="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )" || exit 1
cd "$script_dir" || exit 1

set -x #echo on

# wait for database to open its port for connections
# http://unix.stackexchange.com/a/149053/47781

# syntax like ${DB_CONNECTION-pgsql} is just bash being bash. It uses the DB_CONNECTION value if set, pgsql otherwise
# http://www.tldp.org/LDP/abs/html/parameter-substitution.html

# Drupal calls this the driver, Laravel calls it the DB_CONNECTION
db_driver=${DB_CONNECTION-pgsql}
if [[ $db_driver = 'mysql' ]]; then
	source ./mysql_vars_compat.sh

	if [[ "${MYSQL_HOST}" == '' || "${MYSQL_HOST}" == 'localhost' ]]; then
		# todo: what to do with db_host=localhost? That uses unix socket MYSQL_UNIX_PORT instead of TCP.
		# none of our apps use localhost currently.
		exit
	else
		db_host=${MYSQL_HOST}
		db_port=${MYSQL_TCP_PORT}
	fi
else
	source ./pg_vars_compat.sh

	db_host=${PGHOST}
	db_port=${PGPORT}
fi

echo "Waiting for DB to accept connections on $db_host/$db_port"
while ! timeout 1 bash -c "echo > /dev/tcp/$db_host/$db_port"; do echo "Waiting for database"; sleep 0.5; done
