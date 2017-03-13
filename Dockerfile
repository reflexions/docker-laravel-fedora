FROM fedora:25

EXPOSE 80
WORKDIR /tmp
ENTRYPOINT ["/usr/share/docker-laravel-scripts/start.sh"]

# default is 'dumb'. that cripples less, vim, coloring, etc
ENV TERM xterm-256color

# the fedora base image is trying to enable this, but it's not working. we'll do it manually.
# see: https://git.fedorahosted.org/cgit/spin-kickstarts.git/tree/fedora-docker-base.ks
RUN echo 'tsflags=nodocs' >> /etc/dnf/dnf.conf

# install yarn (npm replacement)
COPY etc/yum.repos.d/yarn.repo /etc/yum.repos.d/yarn.repo

# putting && on next line, because then it's more obvious that
# the new line is a separate command

# install all the packages we need
# enable the remi php 7.1 repo

# SSLProxyEngine requires mod_ssl to connect to a https endpoint
# Usually you'd only have mod_ssl if you were serving https content,
# but we're using CloudFlare for that.
# unzip is used to speed up composer
# findutils provides find and xargs, used by start.sh.
RUN dnf -y upgrade --setopt=deltarpm=false \
    && dnf -y install \
        http://rpms.remirepo.net/fedora/remi-release-25.rpm \
        dnf-plugins-core \
    && dnf config-manager --set-enabled remi remi-php71 \
    && dnf -y remove \
        dnf-plugins-core \
        python3-dnf-plugins-core \
    && dnf -y install \
        composer \
        findutils \
        git \
        hostname \
        ImageMagick \
        mod_ssl \
        php \
        php-gd \
        php-imap \
        php-json \
        php-mbstring \
        php-mysqlnd \
        php-opcache \
        php-pdo \
        php-pecl-memcached \
        php-pgsql \
        php-soap \
        php-xml \
        unzip \
        yarn \
    && dnf clean packages

# Configure php

# configure apache
COPY etc/php.d/php.ini /etc/php.d/local-overrides.ini
COPY etc/httpd/conf.d/vhost.conf /etc/httpd/conf.d/vhost.conf

COPY docker-laravel-scripts/* /usr/share/docker-laravel-scripts/

# start and setup scripts
RUN chmod 755 /usr/share/docker-laravel-scripts/*

# Default ENV
# ------------------
ENV LARAVEL_WWW_PATH=/var/www/laravel \
    LARAVEL_RUN_PATH=/var/run/laravel \
    LARAVEL_STORAGE_PATH=/var/run/laravel/storage \
    LARAVEL_BOOTSTRAP_CACHE_PATH=/var/run/laravel/bootstrap/cache

WORKDIR /var/www/laravel
