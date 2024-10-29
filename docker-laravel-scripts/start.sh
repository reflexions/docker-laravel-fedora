#!/usr/bin/env bash
set -x #echo on

# this script is the main entrypoint. It starts the app at container startup.

if [ ! -f ${LARAVEL_RUN_PATH}/setup-completed ]; then
    echo "You are required to run /usr/share/docker-laravel-scripts/setup.sh in your Dockerfile-fedora before the container starts"
    echo "Also, if you haven't installed laravel yet, run /usr/share/docker-laravel-scripts/new-project.sh after setup.sh"
    exit 1
fi

# reset permissions of laravel run-time caches
chown -R apache:apache ${LARAVEL_RUN_PATH}
find ${LARAVEL_RUN_PATH} -type d -print0 | xargs -0 chmod 775
find ${LARAVEL_RUN_PATH} -type f -print0 | xargs -0 chmod 664

# make sure httpd and php-fpm log dir exists. Sometimes /var/log is a volume mount.
mkdir -p \
    /var/log/httpd \
    /var/log/php-fpm

cd "${LARAVEL_WWW_PATH}" || exit 1

# todo: lock the db while migrations run to prevent other instances from running migrate simultaneously
# beanstalk's leader_only isn't a guarantee, so maybe we use a db lock instead somehow?
# ensure that the environment we're running in has had db updates applied
if [ "$RUN_MIGRATE_FORCED" == 1 ] || [ "${RUN_MIGRATE_FORCED,,}" == 'true' ]; then
    php artisan migrate --force || { echo "migrate failed"; exit 1; }
elif [ "$RUN_MIGRATE" == 1 ] || [ "${RUN_MIGRATE,,}" == 'true' ]; then
    php artisan migrate || { echo "migrate failed"; exit 1; }
fi

# same method used by https://github.com/fedora-cloud/Fedora-Dockerfiles/blob/master/apache/run-apache.sh

# Make sure we're not confused by old, incompletely-shutdown httpd
# context after restarting the container.  httpd won't start correctly
# if it thinks it is already running.
rm -rf /run/httpd/* /tmp/httpd* /run/supervisord.pid

# start processes
echo "Starting the Supervisor daemon"

exec "$SUPERVISORD_BIN" -c /etc/supervisord.conf
