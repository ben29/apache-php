FROM alpine:3.20.3

# SETTINGS
ENV HTTPD_PREFIX=/usr/local/apache2
ENV PATH=$HTTPD_PREFIX/bin:$PATH
ENV HTTPD_VERSION=2.4.62

# COPY FOREGROUND
COPY httpd-foreground /usr/local/bin/

RUN set -eux; \
    adduser -u 82 -D -S -G www-data www-data; \
    apk update && apk upgrade; \
    apk add --no-cache apr apr-util ca-certificates; \
	apk add --no-cache --virtual .build-deps \
		apr-dev \
		apr-util-dev \
		coreutils \
		dpkg-dev dpkg \
		gcc \
		libc-dev \
		curl-dev \
		jansson-dev \
		libxml2-dev \
		lua-dev \
		make \
		nghttp2-dev \
		openssl \
		openssl-dev \
		pcre-dev \
		tar \
		zlib-dev \
		brotli-dev \
	; \
    mkdir /usr/src; \
    cd /usr/src; \
    wget https://dlcdn.apache.org/httpd/httpd-${HTTPD_VERSION}.tar.gz; \
	tar -xf httpd-${HTTPD_VERSION}.tar.gz; \
	rm httpd-${HTTPD_VERSION}.tar.gz; \
	cd httpd-${HTTPD_VERSION}; \
	\
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
	./configure \
		--build="${gnuArch}" \
		--prefix="${HTTPD_PREFIX}" \
		--enable-mods-shared=reallyall \
		--enable-mpms-shared=all \
	; \
	make -j "$(nproc)"; \
	make install; \
    \
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
	httpd -v

# COPY CONFIG
COPY conf/httpd /usr/local/apache2/conf

STOPSIGNAL SIGWINCH

EXPOSE 443

CMD ["httpd-foreground"]