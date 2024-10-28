FROM alpine:3.20.3

ENV DEPEND="apr-dev apr-util-dev libc-dev pcre-dev nghttp2-dev make ca-certificates gcc perl libxml2-dev curl-dev libpng-dev oniguruma-dev libzip-dev"

# SETTINGS
ENV HTTPD_PREFIX=/usr/local/apache2
ENV PATH=$HTTPD_PREFIX/bin:$PATH
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
	make install; \
    # PHP \
    cd ..; \
    wget -q https://www.php.net/distributions/php-${PHP_VERSION}.tar.gz; \
    tar zxf php-${PHP_VERSION}.tar.gz; \
    cd php-${PHP_VERSION}; \
    sh /configure/php.sh; \
    make; \
    find -type f -name '*.a' -delete; \
    make install; \
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
    rm -rf /usr/local/apache2/man*; \
    rm -rf /usr/local/apache2/conf/*; \
    mv /conf/httpd/* /usr/local/apache2/conf/; \
    chmod 755 /httpd-foreground; \
	httpd -v;

STOPSIGNAL SIGWINCH

EXPOSE 443

ENTRYPOINT ["/httpd-foreground"]