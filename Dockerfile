FROM alpine:3.20

# SETTINGS
ENV PATH /etc/httpd/bin:$PATH
ENV HTTPD_VERSION=2.4.62

# install httpd runtime dependencies
# https://httpd.apache.org/docs/2.4/install.html#requirements
RUN set -eux; \
	apk add --no-cache \
		apr \
		apr-util \
		ca-certificates;

RUN set -eux; \
    adduser -u 82 -D -S -G www-data www-data; \
    apk update && apk upgrade; \
	apk add --no-cache --virtual .build-deps \
		apr-dev \
		apr-util-dev \
		coreutils \
		dpkg-dev dpkg \
		gcc \
		gnupg \
		libc-dev \
		patch \
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
    wget https://dlcdn.apache.org/httpd/httpd-${HTTPD_VERSION}.tar.gz; \
	tar -xf httpd-${HTTPD_VERSION}.tar.gz; \
	rm httpd-${HTTPD_VERSION}.tar.gz; \
	cd httpd-${HTTPD_VERSION}; \
	\
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
	./configure \
		--build="$gnuArch" \
		--prefix="/etc/httpd" \
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
	apk add --no-network --virtual .httpd-so-deps $deps; \
	apk del --no-network .build-deps; \
	\
	httpd -v

STOPSIGNAL SIGWINCH

COPY httpd-foreground /usr/local/bin/

EXPOSE 80

CMD ["httpd-foreground"]