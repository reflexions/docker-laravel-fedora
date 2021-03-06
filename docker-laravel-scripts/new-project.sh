#!/usr/bin/env bash

# This script configures composer to make sure it knows about laravel/laravel and reflexions/docker-laravel
# After it has been run once, rerunning it should have no effect.

echo "-----------------------"
echo "START new-project.sh"
echo "-----------------------"

set -x #echo on

# install laravel if it hasn't been setup in the project dir yet
if [ ! -d "${LARAVEL_WWW_PATH}/app" ]; then
    cd ${LARAVEL_WWW_PATH}
    composer create-project --prefer-dist laravel/laravel /tmp/laravel
    rm /tmp/laravel/.env
    mv /tmp/laravel/* ${LARAVEL_WWW_PATH}
    mv /tmp/laravel/.???* ${LARAVEL_WWW_PATH}
    rm -Rf /tmp/laravel
    php artisan key:generate
fi

# run composer install if reflexions/docker-laravel hasn't been installed
if [ ! -d "${LARAVEL_WWW_PATH}/vendor/reflexions/docker-laravel-fedora" ]; then
    cd ${LARAVEL_WWW_PATH}
    composer install
fi
#  require reflexions/docker-laravel if it hasn't been added to composer yet
if [ ! -d "${LARAVEL_WWW_PATH}/vendor/reflexions/docker-laravel-fedora" ]; then
    cd ${LARAVEL_WWW_PATH}
    composer require reflexions/docker-laravel-fedora
    sed -i 's/Illuminate\\Foundation\\Application/Reflexions\\DockerLaravel\\DockerApplication/g' ${LARAVEL_WWW_PATH}/bootstrap/app.php
fi

echo "-----------------------"
echo "END new-project.sh"
echo "-----------------------"
