# this mirrors quay.io/centos/centos:stream9
# use the cubic-kubernetes/sync-docker-image-mirror/sync-centos-mirror.sh script to keep this in sync
FROM us-central1-docker.pkg.dev/reflexions-cubic/centos-mirror/centos9/stream9:latest as updates-installed

# bring this back?
# default is 'dumb'. that cripples less, vim, coloring, etc
#ENV TERM xterm-256color

# putting && on next line, because then it's more obvious that the new line is a separate command
# defining DNF in case we ever want to give something like fedora-minimal another shot
ENV SHELL=/bin/bash
ENV LANG=en_US.utf8
ENV DNF=/usr/bin/dnf
ENV DELTA_RPM_DISABLE="--setopt=deltarpm=false"
ENV NO_DOCS="--nodocs"
ENV UPGRADE_CMD="upgrade"
ENV RHEL_VERSION="9"

# Default ENV
# order is OS env => Dockerfile => .env
# ------------------
ENV PROJECT_ROOT=/var/www/laravel
ENV LARAVEL_WWW_PATH=/var/www/laravel
ENV LARAVEL_RUN_PATH=/var/run/laravel
ENV LARAVEL_STORAGE_PATH=/var/run/laravel/storage
ENV LARAVEL_BOOTSTRAP_CACHE_PATH=/var/run/laravel/bootstrap/cache
ENV REFLEXIONS_SCRIPTS_PATH=/usr/share/docker-laravel-scripts
ENV SUPERVISORD_BIN=/usr/bin/supervisord
ENV PORT=80

EXPOSE 80

# minrate defaults to 1k/s, which means a slow mirror can slow the build to a near-stop
# We tried out fastestmirror but it ended up being slower overall. There was extra time while it tried to determine
# the fastest mirror, and the ranking was based on ping (not bandwidth), so it wasn't that useful.
# Instead we'll bump the minrate and decrease the timeout.
# docs: https://dnf.readthedocs.io/en/latest/conf_ref.html
RUN echo "minrate=200k" >> /etc/dnf/dnf.conf \
	&& echo "timeout=5" >> /etc/dnf/dnf.conf

# because I use ll all the time
COPY ./home/.bashrc /root/

WORKDIR /tmp

ENTRYPOINT ["/usr/share/docker-laravel-scripts/start.sh"]

# the touch is per https://bugzilla.redhat.com/show_bug.cgi?id=1213602
# it's needed for every dnf operation when the host is using overlayfs (like macs and GCR)
RUN touch /var/lib/rpm/* \
	&& ${DNF} -y ${UPGRADE_CMD} ${DELTA_RPM_DISABLE} ${NO_DOCS} \
	&& ${DNF} -y reinstall tzdata \
	&& ${DNF} clean all

FROM updates-installed as php-base

ARG PHP_VERSION

# SSLProxyEngine requires mod_ssl to connect to an https endpoint

# unzip is used to speed up composer

# findutils provides find and xargs, used by start.sh.

# gcc-c++ and make are for building native node addons => install these on a per-project basis

# we create /run/php-fpm because php-fpm is supposed to but isn't

# the touch is per https://bugzilla.redhat.com/show_bug.cgi?id=1213602
# it's needed for every dnf operation when the host is using overlayfs (like macs and GCR)

RUN touch /var/lib/rpm/* \
	&& ${DNF} -y install \
		'dnf-command(config-manager)' \
		https://rpms.remirepo.net/enterprise/remi-release-${RHEL_VERSION}.rpm \
		https://dl.fedoraproject.org/pub/epel/epel-release-latest-${RHEL_VERSION}.noarch.rpm \
	&& ${DNF} -y module install ${NO_DOCS} php:remi-${PHP_VERSION} \
	&& ${DNF} -y install ${NO_DOCS} \
		findutils \
		git \
		hostname \
		htop \
		httpd \
		ImageMagick \
		mod_ssl \
		php \
		php-fpm \
		php-gd \
		php-imap \
		php-intl \
		php-json \
		php-lz4 \
		php-maxminddb \
		php-mbstring \
		php-mysqlnd \
		php-opcache \
		php-pdo \
		php-pecl-apcu \
		php-pecl-imagick \
		php-pecl-memcached \
		php-pgsql \
		php-redis \
		php-soap \
		php-sodium \
		php-xml \
		php-zip \
		supervisor \
		unzip \
		vim \
		zip \
	&& ${DNF} clean all \
	&& mkdir /run/php-fpm

# example of how you could switch php versions in a project extending this image:
# (better if we just have another variant of this build)

## downgrade from php 8.0 to 7.4
## get the list of currently installed php8 packages,
##   it also strips out the "4" in php-lz4, so we add that back manually
## use sed to strip out the verison numbers,
## switch to the php 7.4 stream,
## then reinstall the php packages
## /run/php-fpm is removed when uninstalling php-fpm, and isn't added back when installing it
#RUN dnf module repoquery --quiet --installed php:remi-8.0 | sed -r 's/^([^0-9]*).*/\1/' | sed -r 's/-$//' | grep -v php-lz > old-php.txt \
#	&& echo "php-lz4" >> old-php.txt \
#	&& cat old-php.txt \
#	&& cat old-php.txt | xargs dnf remove -y \
#	&& dnf -y module disable glpi \
#	&& dnf -y module disable composer \
#	&& dnf -y module disable php:remi-8.0 \
#	&& dnf -y module enable php:remi-7.4 \
#	&& cat old-php.txt | xargs dnf install -y \
#	&& mkdir -p /run/php-fpm \
#	&& rm old-php.txt


# centos-8 didn't originally have a supervisor package. It does now. This is how you'd install it if it didn't:
# Env var SUPERVISORD_BIN=/usr/local/bin/supervisord
# http://supervisord.org/installing.html recommends pip
#RUN pip3 install supervisor

# we'll get the latest composer ourselves instead of using the centos package
# per https://tecadmin.net/install-php-composer-on-centos/
RUN curl -sS https://getcomposer.org/installer | php \
	&& mv /tmp/composer.phar /usr/local/bin/composer

# Configure php
COPY etc/php.d/php.ini /etc/php.d/local-overrides.ini
COPY etc/php-fpm.d/www.conf /etc/php-fpm.d/www.conf

# configure apache
COPY etc/httpd/conf.d/* /etc/httpd/conf.d/

# make Listen use a variable, PORT
RUN sed -i 's/Listen 80/Listen \${PORT}/' /etc/httpd/conf/httpd.conf

# supervisord
COPY etc/supervisord.conf /etc/supervisord.conf
COPY etc/supervisord.d/* /etc/supervisord.d/

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
#	"/var/www/laravel", \
#	"/var/run/laravel/storage"
]

WORKDIR $PROJECT_ROOT

ARG GIT_BRANCH=''
LABEL GIT_BRANCH="${GIT_BRANCH}"

# OpenContainers Annotations
# https://specs.opencontainers.org/image-spec/annotations/
ARG GIT_COMMIT_HASH=''
ARG BUILD_DATE=''
LABEL org.opencontainers.image.url="https://github.com/reflexions/reflexions-drupal"
LABEL org.opencontainers.image.revision="${GIT_COMMIT_HASH}"
LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.title="Reflexions Drupal CentOS ${RHEL_VERSION} + PHP ${PHP_VERSION} Base Image"
LABEL org.opencontainers.image.vendor="Reflexions"

# wipe base image label-schema (superceded by OpenContainers Annotations)
LABEL org.label-schema.vendor=""
LABEL org.label-schema.name=""
LABEL org.label-schema.license="Proprietary"
LABEL org.label-schema.build-date=""
LABEL io.buildah.version=""


# =================================================
FROM quay.io/centos/centos:stream9 as php-base-squashed
COPY --from=php-base / /


# =================================================
FROM php-base as with-node

ARG NODE_MAJOR_VERSION

LABEL org.opencontainers.image.title="Reflexions Laravel CentOS ${RHEL_VERSION} + PHP ${PHP_VERSION} + Node ${NODE_MAJOR_VERSION} Base Image"

WORKDIR /tmp
# centos9 has nodejs 16 out of the box
# it supports LTS (even) releases up to 20 with dnf modules
# for the rest, we'll download bins from nodejs.org (which 'dnf upgrade' will not keep up to date)
# node < 12 needs unsafe param for https://stackoverflow.com/questions/52196518/could-not-get-uid-gid-when-building-node-docker#comment97210945_52196681
# that doesn't work in node 18+ (maybe 16+?) though, so only apply it to node < 12
# (only saw that in google-hosted cloud build, not cloud-build-local for some reason)
RUN available_modules=("18" "20") \
	&& value="\<${1}\>" \
	&& if [[ "${NODE_MAJOR_VERSION}" = "16" ]]; then \
		touch /var/lib/rpm/* \
		&& ${DNF} -y install ${NO_DOCS} \
			nodejs \
			nodejs-full-i18n \
		&& ${DNF} clean all; \
	elif [[ ${available_modules[@]} =~ "${NODE_MAJOR_VERSION}" ]]; then \
		touch /var/lib/rpm/* \
		&& ${DNF} -y module install ${NO_DOCS} \
		nodejs:${NODE_MAJOR_VERSION}/common \
		&& ${DNF} -y install \
		nodejs-full-i18n \
		&& ${DNF} clean all; \
	else \
		curl https://nodejs.org/dist/latest-v${NODE_MAJOR_VERSION}.x/SHASUMS256.txt -o node-shasum256.txt \
		&& if [ $(uname -m) == "aarch64" ]; then \
			node_tar_gz=$(grep node node-shasum256.txt | grep linux | grep arm64.tar.gz); \
		else \
			node_tar_gz=$(grep node node-shasum256.txt | grep linux | grep x64.tar.gz); \
		fi \
		&& node_tar_gz=$(echo "${node_tar_gz}" | cut -f3 -d' ') \
		&& node_dir=$(echo "${node_tar_gz}" | sed 's/.tar.gz//') \
		&& curl --no-progress-meter "https://nodejs.org/dist/latest-v${NODE_MAJOR_VERSION}.x/${node_tar_gz}" -o "${node_tar_gz}" \
		&& sha256sum --check --ignore-missing node-shasum256.txt \
		&& tar zxf "${node_tar_gz}" \
		&& cp -rf "${node_dir}"/* /usr/ \
		&& if [ "${NODE_MAJOR_VERSION}" -lt '12' ]; then \
			npm config set unsafe-perm true; \
		fi; \
	fi

WORKDIR $PROJECT_ROOT

# alternatively from nodesource (but fails on centos9 with unsupported SHA1 hash)
#RUN touch /var/lib/rpm/* \
#	&& dnf -y install \
#		https://rpm.nodesource.com/pub_${NODE_MAJOR_VERSION}.x/nodistro/repo/nodesource-release-nodistro-1.noarch.rpm \
#	&& dnf -y install \
#		nodejs \
#	&& dnf clean all

# installing yarn from the dnf repo was crashing
# https://github.com/nodejs/help/issues/3202
# but installing through npm works
# and this version is newer than the dnf repo
RUN npm install -g yarn

RUN adduser node --user-group --shell=/sbin/nologin


# =================================================
FROM quay.io/centos/centos:stream9 as with-node-squashed
COPY --from=with-node / /

# =================================================
FROM with-node as with-gcloud

LABEL org.opencontainers.image.title="Reflexions Laravel CentOS ${RHEL_VERSION} + PHP ${PHP_VERSION} + Node ${NODE_MAJOR_VERSION} + google-cloud-cli Base Image"

# we leave google-cloud-sdk disabled because it's often slow/offline
RUN printf "\
[google-cloud-sdk]\n\
name=Google Cloud SDK\n\
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el\$releasever-\$basearch\n\
enabled=0\n\
gpgcheck=1\n\
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg,https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg\n\
" > /etc/yum.repos.d/google-cloud-sdk.repo

# since google-cloud-sdk repo is so slow, we temporarily remove any dnf ratelimits
RUN cp /etc/dnf/dnf.conf /etc/dnf/dnf.conf.bak
RUN grep -vF 'minrate=' /etc/dnf/dnf.conf > /etc/dnf/dnf.conf.tmp
RUN grep -vF 'timeout=' /etc/dnf/dnf.conf.tmp > /etc/dnf/dnf.conf

# gcloud needs `which` during install and runtime
RUN touch /var/lib/rpm/* \
	&& ${DNF} -y install --enablerepo=google-cloud-sdk \
		google-cloud-cli \
	&& ${DNF} clean all

RUN mv -f /etc/dnf/dnf.conf.bak /etc/dnf/dnf.conf
