#!/usr/bin/env bash

# run this during image build for a debug build

# iproute provides 'ip', which we use in xdebug-configure.sh
# the touch is per https://bugzilla.redhat.com/show_bug.cgi?id=1213602
# it's needed for every yum operation when the host is using overlayfs (like macs and GCR)
touch /var/lib/rpm/*
${DNF} -y install \
    iproute \
    php-pecl-xdebug3
${DNF} clean all

echo "xdebug.mode=debug" >> /etc/php.d/15-xdebug.ini
echo "xdebug.start_with_request=yes" >> /etc/php.d/15-xdebug.ini
