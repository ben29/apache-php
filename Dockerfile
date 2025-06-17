# ---- Stage 1: Build Apache HTTP Server ----
FROM debian:12.11 AS build-apache

ARG HTTPD_VERSION=2.4.63
ARG DEPEND="libapr1-dev libaprutil1-dev gcc libpcre3-dev zlib1g-dev \
            libssl-dev libnghttp2-dev make wget autoconf libtool perl"

# Copy build scripts
COPY configure/httpd.sh /usr/local/src/httpd.sh

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends $DEPEND ca-certificates curl; \
    rm -rf /var/lib/apt/lists/*; \
    cd /usr/local/src; \
    wget -q https://dlcdn.apache.org/httpd/httpd-${HTTPD_VERSION}.tar.gz; \
    tar -xf httpd-${HTTPD_VERSION}.tar.gz; \
    cd httpd-${HTTPD_VERSION}; \
    sh /usr/local/src/httpd.sh; \
    make -j"$(nproc)"; \
    make install; \
    ls /usr/local/bin; \
    strip /usr/local/bin/httpd

# ---- Stage 2: Build PHP ----
FROM debian:12.11 AS build-php

ARG PHP_VERSION=8.4.8
ARG DEPEND="gcc g++ make autoconf libtool perl wget \
            libxml2-dev libcurl4-openssl-dev libpng-dev \
            libonig-dev libsodium-dev libzip-dev libssl-dev \
            libpcre3-dev zlib1g-dev"

# Copy build script
COPY configure/php.sh /usr/local/src/php.sh

COPY --from=build-apache /usr/local/bin /usr/local/bin
COPY --from=build-apache /var/www/build /var/www/build

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends $DEPEND ca-certificates curl; \
    rm -rf /var/lib/apt/lists/*; \
    cd /usr/local/src; \
    wget -q https://www.php.net/distributions/php-${PHP_VERSION}.tar.gz; \
    tar -xf php-${PHP_VERSION}.tar.gz; \
    cd php-${PHP_VERSION}; \
    sh /usr/local/src/php.sh; \
    make -j"$(nproc)"; \
    find -type f -name '*.a' -delete; \
    make install; \
    strip /usr/local/bin/php; \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer

# ---- Stage 3: Final Runtime Image ----
FROM debian:12.11

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libapr1 libaprutil1 libpcre3 zlib1g libssl3 libnghttp2-14 \
    libxml2 libcurl4 libpng16-16 libonig5 libsodium23 libzip4 \
    ca-certificates curl && rm -rf /var/lib/apt/lists/*

# Set up directories and permissions
RUN mkdir -p /var/www/htdocs && \
    mkdir -p /var/log/httpd && \
    mkdir -p /var/run && \
    chown -R www-data:www-data /var/www /var/log/httpd /var/run

# Copy Apache config
COPY --chown=www-data:www-data conf/httpd /etc/httpd/conf

# Copy php.ini
COPY conf/php/php.ini /etc/php.ini

# Copy binaries
COPY --from=build-apache /usr/local/bin/httpd /usr/local/bin/httpd
COPY --from=build-apache /usr/local/bin/apachectl /usr/local/bin/apachectl
COPY --from=build-php /usr/local/bin/php /usr/local/bin/php
COPY --from=build-php /usr/bin/composer /usr/bin/composer

# Entrypoint
COPY --chown=www-data:www-data --chmod=755 apache2-foreground /apache2-foreground

# Set working directory
WORKDIR /var/www/htdocs

# Apache expects these logs and pid files
RUN ln -sfT /dev/stderr /var/log/httpd/error_log && \
    ln -sfT /dev/stdout /var/log/httpd/access_log

# Expose ports
EXPOSE 80 443
STOPSIGNAL SIGWINCH

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s CMD curl -f http://localhost/ || exit 1

# Switch to non-root user
USER www-data

ENTRYPOINT ["/apache2-foreground"]