# ---- Build Apache, PHP, and Composer in a single layer with Alpine ----
FROM alpine:3.22.0

ARG HTTPD_VERSION=2.4.63
ARG PHP_VERSION=8.4.8

# Copy build scripts
COPY configure/ /usr/local/src

# Install build dependencies
RUN set -eux; \
    addgroup -g 82 www-data && adduser -D -u 82 -G www-data www-data; \
    # Define build-time dependencies
    BUILD_DEPS="g++ make apr-dev apr-util-dev pcre-dev nghttp2-dev perl libxml2-dev curl-dev libpng-dev icu-dev oniguruma-dev libzip-dev binutils pkgconfig wget"; \
    # Install build dependencies
    apk add --no-cache --virtual .build-deps $BUILD_DEPS; \
    # Download and build Apache
    cd /usr/local/src; \
    wget -q https://dlcdn.apache.org/httpd/httpd-${HTTPD_VERSION}.tar.gz; \
    tar -xf httpd-${HTTPD_VERSION}.tar.gz; \
    cd httpd-${HTTPD_VERSION}; \
    sh /usr/local/src/httpd.sh; \
    make -j "$(nproc)"; \
    make install; \
    # Apache-specific configuration
    chown -R www-data:www-data /var/www && \
    ln -sfT /dev/stderr /var/log/error_log && \
    ln -sfT /dev/stdout /var/log/access_log; \
    # Download and build PHP
    cd /usr/local/src; \
    wget -q https://www.php.net/distributions/php-${PHP_VERSION}.tar.gz; \
    tar zxf php-${PHP_VERSION}.tar.gz; \
    cd php-${PHP_VERSION}; \
    sh /usr/local/src/php.sh; \
    make -j "$(nproc)"; \
    make install; \
    # Install Composer
    cd /usr/local/src; \
    wget -q https://getcomposer.org/installer -O composer-setup.php; \
    php -n composer-setup.php -- --install-dir=/usr/bin --filename=composer; \
    # Strip unnecessary symbols from binaries to reduce size
    find /usr/local/bin/ -type f -executable -exec strip --strip-unneeded {} \; || true; \
    # Remove build dependencies
    apk del --no-network .build-deps; \
    # Install runtime-only dependencies
    apk add --no-cache libxml2 libpng icu-libs oniguruma libzip curl pcre2 ca-certificates; \
    # Clean up source and misc files
    rm -rf /usr/local/src/* /var/lib/apt/lists/* /var/www/man* /etc/php /var/www/htdocs/index.html;

# Copy configurations and binaries
COPY --chown=www-data:www-data conf/httpd /etc/httpd/conf
COPY --chown=www-data:www-data --chmod=755 apache2-foreground /apache2-foreground

# Expose ports
EXPOSE 80 443

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s \
    CMD curl -f http://localhost/ || exit 1

# Set working directory
WORKDIR /var/www/htdocs

# Run as non-root user
USER www-data

# Entrypoint script
ENTRYPOINT ["/apache2-foreground"]