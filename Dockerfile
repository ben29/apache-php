# https://github.com/docker-library/php/tree/master/8.3/bookworm/apache
FROM debian:bookworm-slim

# Settings
ENV DEPEND="wget g++ gcc make libexpat-dev libpcre2-dev zlib1g-dev libssl-dev libxml2"
ARG APR_VERSION=1.7.5
ARG APR_UTIL_VERSION=1.6.3
ARG PHP_VERSION=8.3.2
ARG NGHTTP2_VERSION=1.64.0
ARG HTTPD_VERSION=2.4.62

# Download Urls
ENV APR_URL="https://dlcdn.apache.org/apr/apr-${APR_VERSION}.tar.gz"
ENV APR_UTIL_URL="https://dlcdn.apache.org//apr/apr-util-${APR_UTIL_VERSION}.tar.gz"
ENV NGHTTP2_URL="https://github.com/nghttp2/nghttp2/releases/download/v${NGHTTP2_VERSION}/nghttp2-${NGHTTP2_VERSION}.tar.gz"
ENV PHP_URL="https://www.php.net/distributions/php-${PHP_VERSION}.tar.gz"
ENV HTTPD_URL="https://dlcdn.apache.org/httpd/httpd-${HTTPD_VERSION}.tar.gz"

# APR Build
RUN set -eux; \
    apt update && apt upgrade; \
    apt install -y --no-install-recommends ${DEPEND}; \
    rm -rf /var/lib/apt/lists/*; \
    cd /usr/local/src; \
    wget --no-check-certificate ${APR_URL}; \
    tar zvxf apr-${APR_VERSION}.tar.gz; \
    cd apr-${APR_VERSION}; \
    ./configure \
        '--bindir=/usr/bin' \
        '--sbindir=/usr/sbin' \
        '--includedir=/usr/include/apr' \
        '--libexecdir=/usr/local/libexec' \
        '--libdir=/lib64/apr' \
        '--disable-lfs' \
        '--disable-dso' \
        '--disable-timedlocks' \
        '--disable-ipv6'; \
    make && make install;

# APR - UTIL Build
RUN set -eux; \
    cd /usr/local/src; \
    wget --no-check-certificate ${APR_UTIL_URL}; \
    tar zvxf apr-util-${APR_UTIL_VERSION}.tar.gz; \
    cd apr-util-${APR_UTIL_VERSION}; \
    ./configure \
        "--bindir=/usr/bin" \
        "--sbindir=/usr/sbin" \
        "--includedir=/usr/include/apr-until" \
        "--libexecdir=/usr/local/libexec" \
        "--libdir=/lib64" \
        "--with-apr=/usr" \
        "--disable-util-dso"; \
    make && make install;

# HTTP2 Build
RUN set -eux; \
    cd /usr/local/src; \
    wget --no-check-certificate ${NGHTTP2_URL}; \
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
        --disable-app; \
    make && make install;

# HTTPD - BUILD \
RUN set -eux; \
    cd /usr/local/src; \
    wget --no-check-certificate ${HTTPD_URL}; \
    tar zvxf httpd-${HTTPD_VERSION}.tar.gz; \
    cd httpd-${HTTPD_VERSION}; \
    ./configure \
        --prefix=/etc/httpd \
        --exec-prefix=/etc/httpd \
        --bindir=/usr/bin \
        --sbindir=/usr/sbin \
        --sysconfdir=/etc/httpd/conf \
        --includedir=/usr/include/apache \
        --libexecdir=/usr/local/libexec \
        --libdir=/lib64 \
        --mandir=/usr/share/man \
        --datadir=/var/www \
        --localstatedir=/var \
        --with-apr=/usr \
        --with-pcre=/usr \
        --with-z=/usr/local \
        --with-ssl=/usr \
        --with-mpm=event \
        --with-sslport=443 \
        --with-nghttp2=/usr/include \
        --enable-deflate \
        --enable-unique-id \
        --enable-mods-static=most \
        --enable-logio \
        --enable-ssl \
        --enable-rewrite \
        --enable-expires \
        --enable-reqtimeout \
        --enable-headers \
        --enable-http2 \
        --enable-allowmethods \
        --enable-proxy-fcgi \
        --disable-actions \
        --disable-authn-socache \
        --disable-file-cache \
        --disable-cache \
        --disable-cache-disk \
        --disable-cache-socache \
        --disable-socache-dbm \
        --disable-socache-memcache \
        --disable-socache-redis \
        --disable-socache-dc \
        --disable-md \
        --disable-buffer \
        --disable-userdir \
        --disable-status \
        --disable-dav \
        --disable-autoindex \
        --disable-cgi \
        --disable-cgid \
        --disable-info \
        --disable-sed \
        --disable-version \
        --disable-auth-form \
        --disable-auth-digest \
        --disable-auth-basic \
        --disable-authn-core \
        --disable-authn-file \
        --disable-authn-dbm \
        --disable-authn-dbd \
        --disable-authn-anon \
        --disable-authz-groupfile \
        --disable-authz-user \
        --disable-authz-dbm \
        --disable-authz-owner \
        --disable-authz-dbd \
        --disable-authn-socache \
        --disable-watchdog \
        --disable-access-compat \
        --disable-macro \
        --disable-dbd \
        --disable-ext-filter \
        --disable-session-dbd \
        --disable-suexec \
        --disable-substitute \
        --disable-log-debug \
        --disable-speling \
        --disable-proxy-html \
        --disable-proxy-connect \
        --disable-proxy-ftp \
        --disable-proxy-http \
        --disable-proxy-scgi \
        --disable-proxy-uwsgi \
        --disable-proxy-ajp \
        --disable-proxy-balancer \
        --disable-proxy-express \
        --disable-proxy-wstunnel \
        --disable-proxy-fdpass \
        --disable-vhost-alias; \
    make && make install;

# Expose ports 80 and 443
EXPOSE 80
EXPOSE 443

CMD [ "httpd -DFOREGROUND"]