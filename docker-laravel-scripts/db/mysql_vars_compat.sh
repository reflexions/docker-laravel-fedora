#!/usr/bin/env bash

# we're moving over from using DB_HOST et al. to MYSQL_*. The latter is used by the mysql client.
# https://dev.mysql.com/doc/refman/8.4/en/environment-variables.html
export MYSQL_HOST=${MYSQL_HOST-${DB_HOST}}
export MYSQL_TCP_PORT=${MYSQL_TCP_PORT-${DB_PORT-3306}}

# note that MYSQL_PWD is deprecated
export MYSQL_PWD=${MYSQL_PWD-${DB_PASSWORD}}

# mysql doesn't have vars for the database or user but can use ~/.my.cnf
myCnf="${HOME}/.my.cnf"
# create a my.cnf if one doesn't exist
if [[ ! -f "${myCnf}" ]]; then
	# https://dev.mysql.com/doc/refman/8.4/en/option-files.html#option-file-syntax
	# https://dev.mysql.com/doc/refman/8.4/en/connection-options.html
	cat <<-EOF > "${myCnf}"
	[client]
	database = ${DB_DATABASE}
	user = ${DB_USERNAME}
	password = ${MYSQL_PWD}
	EOF

	if [[ "${MYSQL_HOST}" == '' || "${MYSQL_HOST}" == 'localhost' ]]; then
		cat <<-EOF >> "${myCnf}"
		socket = ${MYSQL_UNIX_PORT}
		EOF
	else
		cat <<-EOF >> "${myCnf}"
		host = ${MYSQL_HOST}
		port = ${MYSQL_TCP_PORT}
		EOF
	fi
fi
