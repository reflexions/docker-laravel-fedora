#!/usr/bin/env bash

# we're moving over from using DB_HOST et al. to PG*. The latter is used by psql.
# https://www.postgresql.org/docs/current/libpq-envars.html
export PGHOST=${PGHOST-${DB_HOST}}
export PGPORT=${PGPORT-${DB_PORT-5432}}
export PGDATABASE=${PGDATABASE-${DB_DATABASE}}
export PGUSER=${PGUSER-${DB_USERNAME}}
export PGPASSWORD=${PGPASSWORD-${DB_PASSWORD}}
