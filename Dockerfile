# https://github.com/docker-library/php/blob/master/8.3/bookworm/apache/Dockerfile
FROM alpine:3.20.3

ENV DEPEND="apr-dev apr-util-dev libc-dev pcre-dev nghttp2-dev make ca-certificates gcc perl libxml2-dev curl-dev libpng-dev oniguruma-dev libzip-dev openssl icu-dev g++"

# SETTINGS
ENV HTTPD_PREFIX=/usr/local/apache2
ENV PATH=$HTTPD_PREFIX/bin:/etc/php/bin:$PATH
ENV HTTPD_VERSION=2.4.62
ENV PHP_VERSION=8.3.13

# COPY FILES
COPY files/ /

RUN set -eux; \
    # ADD  USER
    adduser -u 82 -D -S -G www-data www-data; \
    apk update && apk upgrade; \
	apk add --no-cache --virtual .build-deps $DEPEND; \
    mkdir /usr/src; \
    cd /usr/src; \
    wget -q https://dlcdn.apache.org/httpd/httpd-${HTTPD_VERSION}.tar.gz; \
	tar -xf httpd-${HTTPD_VERSION}.tar.gz; \
	rm httpd-${HTTPD_VERSION}.tar.gz; \
	cd httpd-${HTTPD_VERSION}; \
    sh /configure/httpd.sh; \
	make -j "$(nproc)"; \
	make -j "$(nproc)" install; \
    mkdir -p /var/www/htdocs; \
    chown -R www-data:www-data /var/www/htdocs; \
    rm -rf /usr/local/apache2/man*; \
    rm -rf /usr/local/apache2/conf/*; \
    mv /conf/httpd/* /usr/local/apache2/conf/; \
    chmod 755 /apache2-foreground; \
    ln -sfT /dev/stderr /var/log/error_log; \
    ln -sfT /dev/stdout /var/log/access_log; \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${HTTPD_PREFIX}/server.key -out ${HTTPD_PREFIX}/server.crt -config ${HTTPD_PREFIX}/conf/cert.txt; \
    # PHP \
    cd ..; \
    wget -q https://www.php.net/distributions/php-${PHP_VERSION}.tar.gz; \
    tar zxf php-${PHP_VERSION}.tar.gz; \
    cd php-${PHP_VERSION}; \
    sh /configure/php.sh; \
    make -j $(nproc); \
    find -type f -name '*.a' -delete; \
    make -j install; \
    cp /conf/php/php.ini /etc/php/lib; \
    cd ../; \
    wget -q https://getcomposer.org/installer; \
    php -n installer; \
    mv composer.phar /etc/php/bin; \
    rm -rf installer; \
    # CLEAN
	deps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --no-network --virtual .httpd-so-deps ${deps}; \
	apk del --no-network .build-deps; \
	rm -rf /usr/src; \
    rm -rf /conf; \
	httpd -v;

STOPSIGNAL SIGWINCH

WORKDIR /var/www/htdocs

EXPOSE 80 443

CMD ["/apache2-foreground"]