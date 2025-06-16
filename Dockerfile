# ---- Stage 1: Build Apache and PHP ----
FROM debian:12.11 AS build

ARG HTTPD_VERSION=2.4.63
ARG PHP_VERSION=8.4.8
ARG DEPEND="libapr1-dev libaprutil1-dev gcc libpcre3-dev zlib1g-dev \
            libssl-dev libnghttp2-dev make libxml2-dev libcurl4-openssl-dev \
            libpng-dev g++ libonig-dev libsodium-dev libzip-dev wget \
            autoconf libtool perl"

# Copy configuration and build scripts
COPY conf/httpd /etc/httpd/conf
COPY configure/ /usr/local/src

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends $DEPEND ca-certificates curl; \
    rm -rf /var/lib/apt/lists/*

### Build Apache HTTP Server
RUN set -eux; \
    cd /usr/local/src; \
    wget -q https://dlcdn.apache.org/httpd/httpd-${HTTPD_VERSION}.tar.gz; \
    tar -xf httpd-${HTTPD_VERSION}.tar.gz; \
    cd httpd-${HTTPD_VERSION}; \
    sed -i -e "s/install-conf install-htdocs/install-htdocs/g" Makefile.in; \
    sh /usr/local/src/httpd.sh; \
    make -j"$(nproc)"; \
    make install; \
    # Setup SSL certificates
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout /etc/httpd/conf/server.key \
      -out /etc/httpd/conf/server.crt \
      -config /etc/httpd/conf/cert.txt; \
    # Validate config
    httpd -t

### Build PHP
RUN set -eux; \
    cd /usr/local/src; \
    wget -q https://www.php.net/distributions/php-${PHP_VERSION}.tar.gz; \
    tar -xf php-${PHP_VERSION}.tar.gz; \
    cd php-${PHP_VERSION}; \
    sh /usr/local/src/php.sh; \
    make -j"$(nproc)"; \
    find -type f -name '*.a' -delete; \
    make install

### Install Composer
RUN set -eux; \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer
# ---- Stage 2: Runtime Image ----
FROM debian:12.11

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libapr1 libaprutil1 libpcre3 zlib1g libssl3 libnghttp2-14 \
    libxml2 libcurl4 libpng16-16 libonig5 libsodium23 libzip4 \
    ca-certificates curl && rm -rf /var/lib/apt/lists/*

# Copy Apache install from build
COPY --from=build /etc/httpd /etc/httpd
COPY --from=build /usr/bin/httpd /usr/bin/
COPY --from=build /usr/sbin/httpd /usr/sbin/  # In case it was installed here
COPY --from=build /usr/libexec /usr/libexec   # Apache modules

# Copy PHP binary and related files
COPY --from=build /usr/local/bin/php /usr/local/bin/
COPY --from=build /usr/local/lib /usr/local/lib

# Optional: copy php.ini if you're using one
COPY --from=build /usr/local/src/conf/php/php.ini /etc/php/php.ini

# Copy apache2-foreground script
COPY --chown=www-data:www-data --chmod=755 apache2-foreground /apache2-foreground

# Log redirection
RUN ln -sfT /dev/stderr /var/log/error_log && \
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