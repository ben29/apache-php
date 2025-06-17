# ---- Build Apache, PHP, and Composer in a single layer ----
FROM debian:12.11-slim AS build

ARG HTTPD_VERSION=2.4.63
ARG PHP_VERSION=8.4.8

# Copy build scripts
COPY configure/ /usr/local/src

RUN set -eux; \
    # Define dependencies
    DEPEND="libapr1-dev libaprutil1-dev gcc libpcre3-dev zlib1g-dev libssl-dev \
    libnghttp2-dev make libxml2-dev libcurl4-openssl-dev libpng-dev g++ \
    libonig-dev libsodium-dev libzip-dev wget ca-certificates curl"; \
    # Install build dependencies
    apt-get update && apt-get install -y --no-install-recommends $DEPEND; \
    rm -rf /var/lib/apt/lists/*; \
    # Build Apache HTTP Server
    cd /usr/local/src; \
    wget -q https://dlcdn.apache.org/httpd/httpd-${HTTPD_VERSION}.tar.gz; \
    tar -xf httpd-${HTTPD_VERSION}.tar.gz; \
    rm httpd-${HTTPD_VERSION}.tar.gz; \
    cd httpd-${HTTPD_VERSION}; \
    sh /usr/local/src/httpd.sh; \
    make -j "$(nproc)"; \
    make install; \
    chown -R www-data:www-data /etc/httpd /var/www; \
    ln -sfT /dev/stderr /var/log/error_log; \
    ln -sfT /dev/stdout /var/log/access_log; \
    # Build PHP (mod_php)
    cd /usr/local/src; \
    wget -q https://www.php.net/distributions/php-${PHP_VERSION}.tar.gz; \
    tar zxf php-${PHP_VERSION}.tar.gz; \
    cd php-${PHP_VERSION}; \
    sh /usr/local/src/php.sh; \
    make -j "$(nproc)"; \
    find -type f -name '*.a' -delete; \
    make install; \
    # Install Composer
    #cd /usr/local/src; \
    #wget -q https://getcomposer.org/installer; \
    #php -n installer; \
    #mv composer.phar /usr/bin/; \
    # Prepare the entrypoint script
    # Clean up build dependencies and unnecessary files
    apt-get purge -y --auto-remove gcc make g++ wget; \
    apt autoremove -y; \
    rm -rf /var/www/man* /usr/local/src/* /var/lib/apt/lists/*;

# ---- Runtime Image ----
# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates libssl-dev libnghttp2-dev libpcre3-dev \
    libaprutil1-dev libxml2-dev libcurl4-openssl-dev \
    libonig-dev libsodium-dev libzip-dev; \
    rm -rf /var/lib/apt/lists/*;

# Copy configurations and binaries
COPY --chown=www-data:www-data conf/httpd /etc/httpd/conf
COPY --chown=www-data:www-data --from=build /etc/httpd/modules /etc/httpd/modules
#COPY conf/php/php.ini /etc/php.ini
COPY --from=build /usr/local/bin/httpd /usr/local/bin/
COPY --from=build /usr/local/bin/apachectl /usr/local/bin/
COPY --from=build /usr/local/bin/php /usr/local/bin/
COPY --from=build /usr/bin/composer /usr/bin/
COPY --chown=www-data:www-data --chmod=755 apache2-foreground /apache2-foreground

# Prepare logs and htdocs directory
RUN mkdir -p /var/www/htdocs && \
    chown -R www-data:www-data /var/www/htdocs && \
    ln -sfT /dev/stderr /var/log/error_log && \
    ln -sfT /dev/stdout /var/log/access_log;

# Set working directory
WORKDIR /var/www/htdocs

# Expose ports
EXPOSE 80 443

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s \
    CMD curl -f http://localhost/ || exit 1

# Run as non-root user
USER www-data

# Entrypoint script
ENTRYPOINT ["/apache2-foreground"]