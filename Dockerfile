# ---- Stage 1: Build Apache and PHP ----
FROM debian:12.11 AS build

ARG HTTPD_VERSION=2.4.63
ARG PHP_VERSION=8.4.8
ARG DEPEND="libapr1-dev libaprutil1-dev gcc libpcre3-dev zlib1g-dev \
            libssl-dev libnghttp2-dev make libxml2-dev libcurl4-openssl-dev \
            libpng-dev g++ libonig-dev libsodium-dev libzip-dev wget \
            autoconf libtool perl"

# Copy build scripts
COPY configure/ /usr/local/src

### Build Apache HTTP Server
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
    make install;
    # Validate config
    #httpd -t

### Build PHP
RUN set -eux; \
    cd /usr/local/src; \
    wget -q https://www.php.net/distributions/php-${PHP_VERSION}.tar.gz; \
    tar -xf php-${PHP_VERSION}.tar.gz; \
    cd php-${PHP_VERSION}; \
    sh /usr/local/src/php.sh; \
    make -j"$(nproc)"; \
    find -type f -name '*.a' -delete; \
    make install; \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer; \
    find /usr/local/bin -type f ! \( -name apachectl -o -name php -o -name httpd \) -delete;

# ---- Stage 2: Runtime Image ----
FROM debian:12.11

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libapr1 libaprutil1 libpcre3 zlib1g libssl3 libnghttp2-14 \
    libxml2 libcurl4 libpng16-16 libonig5 libsodium23 libzip4 \
    ca-certificates curl && rm -rf /var/lib/apt/lists/*

# Runtime: Copy only necessary files
COPY --chown=www-data:www-data conf/httpd /etc/httpd
COPY --chown=www-data:www-data --from=build /usr/local/bin /usr/local/bin
COPY conf/php/php.ini /etc/php.ini

# Entrypoint
COPY --chown=www-data:www-data --chmod=755 apache2-foreground /apache2-foreground

# Log redirection
#RUN ln -sfT /dev/stderr /var/log/error_log && \
#    ln -sfT /dev/stdout /var/log/access_log

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