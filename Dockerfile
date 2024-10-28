FROM alpine:3.20.3

ENV DEPEND="apr-dev apr-util-dev libc-dev pcre-dev nghttp2-dev make ca-certificates"

# SETTINGS
ENV HTTPD_PREFIX=/usr/local/apache2
ENV PATH=$HTTPD_PREFIX/bin:$PATH
ENV HTTPD_VERSION=2.4.62
ENV PHP_VERSION=8.3.13

# COPY FILES
COPY files /

RUN set -eux; \
    # ADD  USER
    adduser -u 82 -D -S -G www-data www-data; \
    apk update && apk upgrade; \
	apk add --no-cache --virtual .build-deps $DEPEND; \
    mkdir /usr/src; \
    cd /usr/src; \
    wget https://dlcdn.apache.org/httpd/httpd-${HTTPD_VERSION}.tar.gz; \
	tar -xf httpd-${HTTPD_VERSION}.tar.gz; \
	rm httpd-${HTTPD_VERSION}.tar.gz; \
	cd httpd-${HTTPD_VERSION}; \
    sh /files/conifgure/httpd.sh; \
    exit; \
	make -j "$(nproc)"; \
	make install; \
    # PHP \
    cd ..; \
    wget https://www.php.net/distributions/php-${PHP_VERSION}.tar.gz; \
    tar zxf php-${PHP_VERSION}.tar.gz; \
    cd php-${PHP_VERSION}; \
    './configure' \
        '--build=x86_64-linux-gnu' \
        'build_alias=x86_64-linux-gnu' \
        '--with-libdir=lib/x86_64-linux-gnu' \
        "--with-mysqli=mysqlnd" \
        "--with-pdo-mysql=mysqlnd" \
        '--with-config-file-path=/usr/local/etc/php' \
        '--with-config-file-scan-dir=/usr/local/etc/php/conf.d' \
        "--with-fpm-user=www-data" \
        "--with-fpm-group=www-data" \
        "--with-openssl" \
        "--with-iconv" \
        "--with-curl" \
        "--with-zlib" \
        "--with-libxml" \
        "--with-zip" \
        "--with-sodium" \
        "--with-apxs2" \
        "--enable-filter" \
        "--enable-ctype" \
        "--enable-xml" \
        "--enable-tokenizer" \
        "--enable-dom" \
        "--enable-simplexml" \
        "--enable-calendar" \
        "--enable-pdo" \
        "--enable-phar" \
        "--enable-session" \
        "--enable-mbstring" \
        "--enable-bcmath" \
        "--enable-exif" \
        "--enable-fileinfo" \
        "--enable-gd" \
        "--enable-intl" \
        "--enable-zts" \
        "--enable-ipv6" \
        "--disable-cgi" \
        "--disable-phpdbg" \
        "--disable-all"; \
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
    chmod 755 /usr/local/bin/httpd-foreground; \
	httpd -v;


# COPY CONFIG
# COPY conf/httpd /usr/local/apache2/conf

STOPSIGNAL SIGWINCH

EXPOSE 443

CMD ["httpd-foreground"]