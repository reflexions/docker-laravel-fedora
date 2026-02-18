#!/usr/bin/env bash

# we're moving over from using DB_HOST et al. to MYSQL_*. The latter is used by the mysql client.
# https://dev.mysql.com/doc/refman/8.4/en/environment-variables.html
export MYSQL_HOST=${MYSQL_HOST-${DB_HOST}}
export MYSQL_TCP_PORT=${MYSQL_TCP_PORT-${DB_PORT-3306}}

# note that MYSQL_PWD is deprecated
export MYSQL_PWD=${MYSQL_PWD-${DB_PASSWORD}}

function option_escape {
	# replace \ with \\
	# replace ' with \'
	# surround the result with single quotes
	echo "$1" | sed 's|\\|\\\\|g' | sed "s|'|\\\\|g" | sed -r "s|^(.*)$|'\\1'|g"
}

# mysql doesn't have vars for the database or user but can use ~/.my.cnf
myCnf="${HOME}/.my.cnf"
# create a my.cnf if one doesn't exist
if [[ ! -f "${myCnf}" ]]; then
	# https://dev.mysql.com/doc/refman/8.4/en/option-files.html#option-file-syntax
	# https://dev.mysql.com/doc/refman/8.4/en/connection-options.html
	# mysqldump errors if database is in client section https://stackoverflow.com/questions/54024991/error-in-mysqldump-mysqldump-error-unknown-variable-database-somedb
	cat <<-EOF > "${myCnf}"
	[mysql]
	database = $(option_escape "${DB_DATABASE}")

	[client]
	user = $(option_escape "${DB_USERNAME}")
	password = $(option_escape "${MYSQL_PWD}")
	EOF

	if [[ "${MYSQL_HOST}" == '' || "${MYSQL_HOST}" == 'localhost' ]]; then
		cat <<-EOF >> "${myCnf}"
		socket = $(option_escape "${MYSQL_UNIX_PORT}")
		EOF
	else
		cat <<-EOF >> "${myCnf}"
		host = $(option_escape "${MYSQL_HOST}")
		port = $(option_escape "${MYSQL_TCP_PORT}")
		EOF
	fi
fi
