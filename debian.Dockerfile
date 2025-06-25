FROM debian:12.11-slim

ARG HTTPD_VERSION=2.4.63
ARG PHP_VERSION=8.4.8
ARG COMPOSER_VERSION=2.8.9

ENV DEBIAN_FRONTEND=noninteractive

# Copy build scripts
COPY configure/ /usr/local/src

RUN set -eux; \
    apt update; \
    apt install -y --no-install-recommends \
      g++ libpcre3-dev libssl-dev make libexpat1-dev pkg-config wget ca-certificates \
      libxml2-dev zlib1g-dev libcurl4-openssl-dev libpng-dev libonig-dev libsodium-dev libzip-dev; \
    cd /usr/local/src; \
    wget https://dlcdn.apache.org/httpd/httpd-${HTTPD_VERSION}.tar.gz; \
    tar xf httpd-${HTTPD_VERSION}.tar.gz; \
    cd httpd-${HTTPD_VERSION}; \
    wget -O srclib/apr.tar.gz https://dlcdn.apache.org/apr/apr-1.7.6.tar.gz; \
    wget -O srclib/apr-util.tar.gz https://dlcdn.apache.org/apr/apr-util-1.6.3.tar.gz; \
    mkdir -p srclib/apr srclib/apr-util; \
    tar -zxf srclib/apr.tar.gz -C srclib/apr --strip-components=1; \
    tar -zxf srclib/apr-util.tar.gz -C srclib/apr-util --strip-components=1; \
    sh /usr/local/src/httpd.sh; \
    make -j"$(nproc)"; \
    make install; \
    cd /usr/local/src; \
    wget https://www.php.net/distributions/php-${PHP_VERSION}.tar.gz; \
    tar zxf php-${PHP_VERSION}.tar.gz; \
    cd php-${PHP_VERSION}; \
    sh /usr/local/src/php.sh; \
    make -j"$(nproc)"; \
    make install; \
    wget -O /usr/local/bin/composer.phar https://getcomposer.org/download/${COMPOSER_VERSION}/composer.phar; \
    chmod +x /usr/local/bin/composer.phar; \
    # Strip binaries to reduce size
    find /usr/local/bin -type f -executable -exec strip --strip-unneeded {} + || true; \
    # Remove build tools
    apt purge -y --auto-remove \
      g++ libssl-dev make pkg-config wget \
      build-essential libtool autoconf perl binutils; \
    apt remove -y libicu-dev icu-devtools; \
    # Cleanup
    rm -rf /usr/local/src /var/lib/apt/lists/* /var/www/man* /etc/php /etc/httpd/conf/* /var/www/htdocs/index.html; \
    chown -R www-data:www-data /var/www /etc/httpd; \
    ln -sfT /dev/stderr /var/log/error_log; \
    ln -sfT /dev/stdout /var/log/access_log

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
