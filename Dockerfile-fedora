# not using fedora-minimal because it's more hassle than it's worth, e.g. tzdata is marked as installed but the files
# aren't there, and microdnf doesn't support automatically adding gpg keys
FROM fedora:31

# putting && on next line, because then it's more obvious that the new line is a separate command

ENV SHELL=/bin/bash \
    LANG=en_US.utf8 \
    DNF=/usr/bin/dnf \
    DELTA_RPM_DISABLE="--setopt=deltarpm=false" \
    NO_DOCS="--nodocs" \
    UPGRADE_CMD="upgrade"

EXPOSE 80

# select node 12 dnf module
RUN printf "\
[nodejs]\n\
name=nodejs\n\
stream=12\n\
profiles=\n\
state=enabled\n\
" > /etc/dnf/modules.d/nodejs.module

# install yarn repo
RUN printf "\
[yarn]\n\
name=Yarn Repository\n\
baseurl=https://dl.yarnpkg.com/rpm/\n\
enabled=1\n\
gpgcheck=1\n\
gpgkey=https://dl.yarnpkg.com/rpm/pubkey.gpg\n\
" > /etc/yum.repos.d/yarn.repo

# because I use ll all the time
COPY ./home/.bashrc /root/

WORKDIR /var/www/laravel

ENTRYPOINT ["/usr/share/docker-laravel-scripts/start.sh"]


# SSLProxyEngine requires mod_ssl to connect to a https endpoint

# unzip is used to speed up composer

# findutils provides find and xargs, used by start.sh.

# gcc-c++ and make are for building native node addons => install these on a per-project basis

# we create /run/php-fpm because php-fpm is supposed to but isn't

# the touch is per https://bugzilla.redhat.com/show_bug.cgi?id=1213602
# it's needed for every dnf operation when the host is using overlayfs (like macs and GCR)
RUN touch /var/lib/rpm/* \
    && ${DNF} -y ${UPGRADE_CMD} ${DELTA_RPM_DISABLE} ${NO_DOCS} \
    && ${DNF} -y install ${NO_DOCS} \
        composer \
        findutils \
        git \
        hostname \
        httpd \
        ImageMagick \
        mod_ssl \
        nodejs \
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
        php-sodium \
        php-xml \
        supervisor \
        unzip \
        vim \
        yarn \
    && ${DNF} clean all \
    && mkdir /run/php-fpm

# Configure php
COPY etc/php.d/php.ini /etc/php.d/local-overrides.ini
COPY etc/php-fpm.d/php-fpm.ini /etc/php-fpm.d/www.conf

# configure apache
COPY etc/httpd/conf.d/* /etc/httpd/conf.d/

# supervisord
COPY etc/supervisord.conf /etc/supervisord.conf
COPY etc/supervisord.d/* /etc/supervisord.d/

# Default ENV
# order is OS env => Dockerfile-fedora => .env
# ------------------
ENV LARAVEL_WWW_PATH=/var/www/laravel \
    LARAVEL_RUN_PATH=/var/run/laravel \
    LARAVEL_STORAGE_PATH=/var/run/laravel/storage \
    LARAVEL_BOOTSTRAP_CACHE_PATH=/var/run/laravel/bootstrap/cache \
    REFLEXIONS_SCRIPTS_PATH=/usr/share/docker-laravel-scripts

# start and setup scripts
COPY docker-laravel-scripts/* ${REFLEXIONS_SCRIPTS_PATH}/

# so that the volumes are writeable by apache
RUN mkdir /usr/share/httpd/{.cache,.composer,.yarn} \
    && chown apache:apache /usr/share/httpd/{.cache,.composer,.yarn}

VOLUME [ \
    "/usr/share/httpd/.cache", \
    "/usr/share/httpd/.composer", \
    "/usr/share/httpd/.yarn" \
# We won't make these volumes now, but the extending Dockerfile-fedora may want to do this if
# baking those dirs into the image is undesirable.
#    "/var/www/laravel", \
#    "/var/run/laravel/storage"
]
