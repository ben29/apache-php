# ---- Build Apache, PHP, and Composer in a single layer with Alpine ----
FROM alpine:3.22.0

ARG HTTPD_VERSION=2.4.63
ARG PHP_VERSION=8.4.8
ARG COMPOSER_VERSION=2.8.9

# Set ZEND thread stack size
ENV ZEND_THREAD_STACK_SIZE=262144

# Copy build scripts
COPY configure/ /usr/local/src

# Install build and runtime dependencies
RUN set -eux; \
    apk add --no-cache --virtual .build-tools \
      g++ make gcc build-base wget libtool perl; \
    apk add --no-cache --virtual .runtime-libs \
      pcre-dev openssl-dev expat-dev \
      libxml2-dev curl-dev libpng-dev icu-dev oniguruma-dev libzip-dev libsodium-dev; \
    # --- Create user ---
    adduser -S -G www-data www-data; \
    # --- Build Apache ---
    cd /usr/local/src; \
    wget -q https://dlcdn.apache.org/httpd/httpd-${HTTPD_VERSION}.tar.gz; \
    tar -xf httpd-${HTTPD_VERSION}.tar.gz; \
    cd httpd-${HTTPD_VERSION}; \
    # APR & APT -UTIL \
    wget -O srclib/apr.tar.gz https://dlcdn.apache.org/apr/apr-1.7.6.tar.gz; \
    wget -O srclib/apr-util.tar.gz https://dlcdn.apache.org/apr/apr-util-1.6.3.tar.gz; \
    mkdir -p srclib/apr srclib/apr-util; \
    tar -zxf srclib/apr.tar.gz -C srclib/apr --strip-components=1; \
    tar -zxf srclib/apr-util.tar.gz -C srclib/apr-util --strip-components=1; \
    sh /usr/local/src/httpd.sh; \
    make -j"$(nproc)"; \
    make install; \
    # Log config \
    chown -R www-data:www-data /var/www && \
    ln -sfT /dev/stderr /var/log/error_log && \
    ln -sfT /dev/stdout /var/log/access_log; \
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
    wget -q -O /usr/bin/composer.phar https://getcomposer.org/download/${COMPOSER_VERSION}/composer.phar; \
    chmod +x /usr/bin/composer.phar; \
    # Strip executables (safe-fail)
    find /usr/local/bin/ -type f -executable -exec strip --strip-unneeded {} \; || true; \
    # Remove build tools
    apk del .build-tools; \
    # PERMISSIONS \
    chown -R www-data:www-data /etc/httpd; \
    # Cleanup
    rm -rf /usr/local/src /var/www/man* /etc/php /etc/httpd/conf/* /var/www/htdocs/index.html

# Copy configs & startup script
COPY --chown=www-data:www-data conf/httpd /etc/httpd/conf
COPY --chown=www-data:www-data --chmod=755 apache2-foreground /apache2-foreground
COPY conf/php/php.ini /etc

# Expose HTTP/HTTPS
EXPOSE 80 443

# Set workdir, user, and entrypoint
WORKDIR /var/www/htdocs

# Run as non-root user
USER www-data

# Entrypoint script
ENTRYPOINT ["/apache2-foreground"]