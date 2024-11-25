#!/usr/bin/env bash

gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)";
PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64"
PHP_CPPFLAGS="$PHP_CFLAGS"
PHP_LDFLAGS="-Wl,-O1 -pie"

export \
    CFLAGS="$PHP_CFLAGS" \
    CPPFLAGS="$PHP_CPPFLAGS" \
    LDFLAGS="$PHP_LDFLAGS"

./configure \
    "--build=${gnuArch}" \
    "--prefix=/etc" \
    "--sysconfdir=/etc/php/conf" \
    "--bindir=/usr/bin" \
    "--sbindir=/usr/sbin" \
    "--with-config-file-scan-dir=/etc/php" \
    "--with-apxs2" \
    "--with-mysql-sock=/var/lib/mysql/mysql.sock" \
    "--with-mysqli=mysqlnd" \
    "--with-pdo-mysql=mysqlnd" \
    "--with-openssl" \
    "--with-iconv" \
    "--with-curl" \
    "--with-zlib" \
    "--with-libxml" \
    "--with-zip" \
    "--with-sodium" \
    "--with-pic" \
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
    "--enable-opcache" \
    "--enable-bcmath" \
    "--enable-exif" \
    "--enable-fileinfo" \
    "--enable-gd" \
    "--enable-intl" \
    "--enable-xmlreader" \
    "--disable-cgi" \
    "--disable-phpdbg" \
    "--disable-ipv6" \
    "--disable-all"
