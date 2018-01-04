FROM fedora:27
EXPOSE 80

# default is 'dumb'. that cripples less, vim, coloring, etc
ENV TERM xterm-256color
ENV LANG en_US.utf8

# the fedora base image is trying to enable this, but it's not working. we'll do it manually.
# see: https://git.fedorahosted.org/cgit/spin-kickstarts.git/tree/fedora-docker-base.ks
RUN echo 'tsflags=nodocs' >> /etc/dnf/dnf.conf

# install node 8 repo (nodesource-release package)
RUN curl --silent --location https://rpm.nodesource.com/setup_9.x | bash -

# putting && on next line, because then it's more obvious that
# the new line is a separate command

RUN dnf -y upgrade --setopt=deltarpm=false \
    && dnf clean packages

ENTRYPOINT ["/usr/share/docker-laravel-scripts/start.sh"]

# SSLProxyEngine requires mod_ssl to connect to a https endpoint
# unzip is used to speed up composer
# findutils provides find and xargs, used by start.sh.
# gcc-c++ and make are for building native node addons
RUN dnf -y install \
        http://rpms.remirepo.net/fedora/remi-release-27.rpm \
        dnf-plugins-core \
    && dnf config-manager --set-enabled remi remi-php72 \
    && dnf -y remove \
        dnf-plugins-core \
        python3-dnf-plugins-core \
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
        php-fpm \
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
        supervisor \
        unzip \
    && dnf clean packages

# Configure php
COPY etc/php.d/php.ini /etc/php.d/local-overrides.ini
COPY etc/php-fpm.d/php-fpm.ini /etc/php-fpm.d/www.conf

# configure apache
COPY etc/httpd/conf.d/vhost.conf /etc/httpd/conf.d/vhost.conf

# supervisord
COPY etc/supervisord.d/supervisord.conf /etc/supervisord.d/supervisord.conf

# start and setup scripts
COPY docker-laravel-scripts/* /usr/share/docker-laravel-scripts/

# Default ENV
# ------------------
ENV LARAVEL_WWW_PATH=/var/www/laravel \
    LARAVEL_RUN_PATH=/var/run/laravel \
    LARAVEL_STORAGE_PATH=/var/run/laravel/storage \
    LARAVEL_BOOTSTRAP_CACHE_PATH=/var/run/laravel/bootstrap/cache

WORKDIR /var/www/laravel
VOLUME ["/var/www/laravel", "/var/run/laravel/storage"]
