# https://github.com/docker-library/php/tree/master/8.3/bookworm/apache
FROM debian:bookworm-slim

# Settings
ENV DEPEND wget g++ gcc make ibexpat1-dev libpcre2-dev zlib1g-dev libssl-dev libxml2
ARG APR_VERSION=1.7.5
ARG APR_UTIL_VERSION=1.6.3
ARG PHP_VERSION=8.3.2
ARG NGHTTP2_VERSION=1.64.0

# Download Urls
ENV APR_URL="https://dlcdn.apache.org/apr/apr-${APR_VERSION}.tar.gz"
ENV APR_UTIL_URL "https://dlcdn.apache.org//apr/apr-util-${APR_UTIL_VERSION}.tar.gz"
ENV NGHTTP2_URL "https://github.com/nghttp2/nghttp2/releases/download/v${NGHTTP2_VERSION}/nghttp2-${NGHTTP2_VERSION}.tar.gz"
ENV PHP_URL="https://www.php.net/distributions/php-${PHP_VERSION}.tar.gz"

# APR Build
RUN set -eux; \
	apt-get update && apt upgrade; \
	apt-get install -y --no-install-recommends wget; \
	rm -rf /var/lib/apt/lists/*; \
    cd /usr/local/src; \
    wget ${APR_URL}; \
    tar zvxf apr-${APR_VERSION}.tar.gz; \
    cd apr-${APR_VERSION}; \
    ./configure \
        "--bindir=/usr/bin" \
        "--sbindir=/usr/sbin" \
        "--includedir=/usr/include/apr" \
        "--libexecdir=/usr/local/libexec" \
        "--libdir=/lib64/apr" \
        "--disable-lfs" \
        "--disable-dso" \
        "--disable-timedlocks" \
        "--disable-ipv6" \
    make && make install;

# APR - UTIL Build
RUN set -eux; \
    cd /usr/local/src; \
    wget ${APR_UTIL_URL}; \
    tar zvxf apr-util-${APR_UTIL_VERSION}.tar.gz; \
    cd apr-${APR_UTIL_VERSION}; \
    ./configure \
        "--bindir=/usr/bin" \
        "--sbindir=/usr/sbin" \
        "--includedir=/usr/include/apr-until" \
        "--libexecdir=/usr/local/libexec" \
        "--libdir=/lib64" \
        "--with-apr=/usr" \
        "--disable-util-dso" \
    make && make install;

# HTTP2 Build
RUN set -eux; \
    cd /usr/local/src; \
    wget ${NGHTTP2_URL}; \
    tar zvxf nghttp2-${NGHTTP2_VERSION}.tar.gz; \
    cd nghttp2-${NGHTTP2_VERSION}; \
    ./configure \
        --bindir=/usr/bin \
        --sbindir=/usr/sbin \
        --mandir=/usr/share/man \
        --libdir=/lib64 \
        --libexecdir=/lib64 \
        --includedir=/usr/include \
        --sharedstatedir=/usr/share/doc/nghttp2 \
        --docdir=/usr/share/doc/nghttp2 \
        --disable-failmalloc \
        --disable-examples \
        --disable-hpack-tools \
        --disable-assert \
        --disable-app \
    make && make install;