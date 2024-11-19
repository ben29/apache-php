# https://github.com/docker-library/httpd/blob/master/2.4/alpine/Dockerfile
# https://github.com/docker-library/php/blob/master/8.3/bookworm/apache/Dockerfile
FROM debian:12.8

# Set environment variables
ENV HTTPD_VERSION=2.4.62
ENV PHP_VERSION=8.3.13
ARG DEPEND="libapr1-dev libaprutil1-dev gcc libpcre3-dev zlib1g-dev libssl-dev libnghttp2-dev make libxml2-dev libcurl4-openssl-dev libpng-dev g++ libonig-dev libsodium-dev libzip-dev wget"
# Copy files
COPY files/ /usr/local/src

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends $DEPEND ca-certificates curl; \
    rm -rf /var/lib/apt/lists/*; \
    cd /usr/local/src; \
    wget -q https://dlcdn.apache.org/httpd/httpd-${HTTPD_VERSION}.tar.gz; \
    tar -xf httpd-${HTTPD_VERSION}.tar.gz; \
    rm httpd-${HTTPD_VERSION}.tar.gz; \
    cd httpd-${HTTPD_VERSION}; \
    sed -i -e "s/install-conf install-htdocs/install-htdocs/g" Makefile.in; \
    sh /usr/local/src/configure/httpd.sh; \
    make -j "$(nproc)"; \
    make install; \
    mkdir -p /etc/httpd/conf; \
    mv /usr/local/src/conf/httpd/* /etc/httpd/conf; \
    chown -R www-data:www-data /etc/httpd; \
    chown -R www-data:www-data /var/www; \
    ln -sfT /dev/stderr /var/log/error_log; \
    ln -sfT /dev/stdout /var/log/access_log; \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/httpd/conf/server.key -out /etc/httpd/conf/server.crt -config /etc/httpd/conf/cert.txt; \
    httpd -t; \
    # PHP \
    cd ..; \
    wget -q https://www.php.net/distributions/php-${PHP_VERSION}.tar.gz; \
    tar zxf php-${PHP_VERSION}.tar.gz; \
    cd php-${PHP_VERSION}; \
    sh /usr/local/src/configure/php.sh; \
    make -j "$(nproc)"; \
    find -type f -name '*.a' -delete; \
    make install; \
    cp /usr/local/src/conf/php/php.ini /etc/php/lib; \
    cd ../; \
    wget -q https://getcomposer.org/installer; \
    php -n installer; \
    mv composer.phar /usr/bin/; \
    mv /usr/local/src/apache2-foreground /apache2-foreground; \
    chmod 755 /apache2-foreground; \
    # Clean up unnecessary packages \
    apt-get purge -y --auto-remove gcc make g++ wget; \
    apt autoremove -y; \
    rm -rf /var/www/man*; \
    rm -rf /var/www/htdocs/*; \
    rm -rf /usr/local/src/*; \
    httpd -v;

STOPSIGNAL SIGWINCH

WORKDIR /var/www/htdocs

EXPOSE 80 443

CMD ["/apache2-foreground"]