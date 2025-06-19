# ---- Build Apache, PHP, and Composer in a single layer with Alpine ----
FROM alpine:3.22.0

ARG HTTPD_VERSION=2.4.63
ARG PHP_VERSION=8.4.8
ARG COMPOSER_VERSION=2.8.9

# Copy build scripts
COPY configure/ /usr/local/src

# Install build and runtime dependencies
RUN set -eux; \
    apk add --no-cache --virtual .build-tools \
      g++ make gcc build-base wget libtool; \
    apk add --no-cache --virtual .runtime-libs \
      apr-dev apr-util-dev pcre-dev nghttp2-dev perl \
      libxml2-dev curl-dev libpng-dev icu-dev oniguruma-dev libzip-dev; \
    # --- Create user ---
    adduser -S -G www-data www-data; \
    # --- Build Apache ---
    cd /usr/local/src; \
    wget -q https://dlcdn.apache.org/httpd/httpd-${HTTPD_VERSION}.tar.gz; \
    tar -xf httpd-${HTTPD_VERSION}.tar.gz; \
    cd httpd-${HTTPD_VERSION}; \
    sh /usr/local/src/httpd.sh; \
    make -j"$(nproc)"; \
    make install; \
    # Log config
    chown -R www-data:www-data /var/www && \
    ln -sfT /dev/stderr /var/log/error_log && \
    ln -sfT /dev/stdout /var/log/access_log; \
    httpd -t; \
    # --- Build PHP (mod_php) ---
    cd /usr/local/src; \
    wget -q https://www.php.net/distributions/php-${PHP_VERSION}.tar.gz; \
    tar zxf php-${PHP_VERSION}.tar.gz; \
    cd php-${PHP_VERSION}; \
    sh /usr/local/src/php.sh; \
    make -j"$(nproc)"; \
    make install; \
    # --- Install Composer ---
    cd /usr/local/src; \
    wget -q -O /usr/bin/composer https://getcomposer.org/download/${COMPOSER_VERSION}/composer.phar; \
    chmod +x /usr/bin/composer; \
    # Strip executables (safe-fail)
    find /usr/local/bin/ -type f -executable -exec strip --strip-unneeded {} \; || true; \
    # Determine runtime .so deps and install
    deps="$( \
    scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
      | tr ',' '\n' \
      | sort -u \
      | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add --no-network --virtual .httpd-so-deps $deps; \
    # Remove build tools
    apk del .build-tools; \
    # Cleanup
    rm -rf /usr/local/src/* /var/www/man* /etc/php /var/www/htdocs/index.html

# Copy configs & startup script
COPY --chown=www-data:www-data conf/httpd /etc/httpd/conf
COPY --chown=www-data:www-data --chmod=755 apache2-foreground /apache2-foreground
COPY conf/php/php.ini /etc

# Expose HTTP/HTTPS
EXPOSE 80 443

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s CMD curl -f http://localhost/ || exit 1

# Set workdir, user, and entrypoint
WORKDIR /var/www/htdocs

# Run as non-root user
USER www-data

# Entrypoint script
ENTRYPOINT ["/apache2-foreground"]