# ---- Stage 1: Build Apache and PHP ----
FROM debian:12.11-slim AS build

ARG HTTPD_VERSION=2.4.63
ARG PHP_VERSION=8.4.8

# Copy build scripts
COPY configure/ /usr/local/src

### Build Apache HTTP Server
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      wget \
      libapr1-dev libaprutil1-dev gcc libssl-dev libnghttp2-dev make; \
    rm -rf /var/lib/apt/lists/*; \
    cd /usr/local/src; \
    wget -q https://dlcdn.apache.org/httpd/httpd-${HTTPD_VERSION}.tar.gz; \
    tar -xf httpd-${HTTPD_VERSION}.tar.gz; \
    cd httpd-${HTTPD_VERSION}; \
    sh /usr/local/src/httpd.sh; \
    make -j"$(nproc)"; \
    make install; \
    strip --strip-unneeded /usr/local/bin/httpd || true; \
    strip --strip-unneeded /usr/local/bin/apachectl || true; \
    # Clean up unnecessary build dependencies
    apt-get purge -y gcc make wget && apt-get autoremove -y && apt-get clean

### Build PHP (mod_php)
RUN set -eux; \
    apt install -y --no-install-recommends \
      libxml2-dev zlib1g-dev libcurl4-openssl-dev \
      libpng-dev g++ libonig-dev libsodium-dev libzip-dev; \
    cd /usr/local/src; \
    wget -q https://www.php.net/distributions/php-${PHP_VERSION}.tar.gz; \
    tar -xf php-${PHP_VERSION}.tar.gz; \
    cd php-${PHP_VERSION}; \
    sh /usr/local/src/php.sh; \
    make -j"$(nproc)"; \
    find -type f -name '*.a' -delete; \
    make install; \
    strip --strip-unneeded /usr/local/bin/php || true; \
    wget -q -O - https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer; \
    find /usr/local/bin -type f ! \( -name apachectl -o -name php -o -name httpd \) -delete; \
    # Clean up unnecessary build dependencies
    apt-get purge -y g++ wget && apt-get autoremove -y && apt-get clean

# ---- Stage 2: Runtime Image ----
FROM debian:12.11-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libapr1 libaprutil1 libpcre3 zlib1g libssl3 libnghttp2-14 \
    libxml2 libcurl4 libpng16-16 libonig5 libsodium23 libzip4 \
    ca-certificates curl && rm -rf /var/lib/apt/lists/*

# Copy configs
COPY --chown=www-data:www-data conf/httpd /etc/httpd/conf
COPY --chown=www-data:www-data --from=build /etc/httpd/modules /etc/httpd/modules
COPY conf/php/php.ini /etc/php.ini

# Copy binaries
COPY --from=build /usr/local/bin/httpd /usr/local/bin/
COPY --from=build /usr/local/bin/apachectl /usr/local/bin/
COPY --from=build /usr/local/bin/php /usr/local/bin/
COPY --from=build /usr/bin/composer /usr/bin/

# Entrypoint
COPY --chown=www-data:www-data --chmod=755 apache2-foreground /apache2-foreground

# Prepare logs and htdocs directory
RUN mkdir -p /var/www/htdocs && \
    chown -R www-data:www-data /var/www/htdocs && \
    ln -sfT /dev/stderr /var/log/error_log && \
    ln -sfT /dev/stdout /var/log/access_log

# Set working directory
WORKDIR /var/www/htdocs

# Expose ports
EXPOSE 80 443

STOPSIGNAL SIGWINCH

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s \
    CMD curl -f http://localhost/ || exit 1

# Run as non-root
USER www-data

# Entrypoint script
ENTRYPOINT ["/apache2-foreground"]