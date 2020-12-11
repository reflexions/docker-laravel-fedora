#!/usr/bin/env bash

# run this during container start in a debug build

# set the xdebug client_host
grep -vF 'xdebug.client_host' /etc/php.d/15-xdebug.ini > /etc/php.d/15-xdebug.ini.tmp
mv -f /etc/php.d/15-xdebug.ini.tmp /etc/php.d/15-xdebug.ini
echo "xdebug.client_host="$(ip route show 0.0.0.0/0 | grep -Eo 'via \S+' | awk '{ print $2 }') >> /etc/php.d/15-xdebug.ini
