FROM fedora:26

EXPOSE 80
WORKDIR /tmp
ENTRYPOINT ["/usr/share/docker-laravel-scripts/start.sh"]

# default is 'dumb'. that cripples less, vim, coloring, etc
ENV TERM xterm-256color
ENV LANG en_US.utf8

# the fedora base image is trying to enable this, but it's not working. we'll do it manually.
# see: https://git.fedorahosted.org/cgit/spin-kickstarts.git/tree/fedora-docker-base.ks
RUN echo 'tsflags=nodocs' >> /etc/dnf/dnf.conf

# install node 8 repo (nodesource-release package)
RUN curl --silent --location https://rpm.nodesource.com/setup_8.x | bash -

# putting && on next line, because then it's more obvious that
# the new line is a separate command

# SSLProxyEngine requires mod_ssl to connect to a https endpoint
# unzip is used to speed up composer
# findutils provides find and xargs, used by start.sh.
# gcc-c++ and make are for building native node addons
RUN dnf -y upgrade --setopt=deltarpm=false \
    && dnf -y install \
        composer \
        findutils \
        gcc-c++ \
        git \
        hostname \
        ImageMagick \
        make \
        mod_ssl \
        nodejs \
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
        php-redis \
        php-soap \
        php-xml \
        unzip \
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
