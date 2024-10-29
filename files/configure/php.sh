#!/usr/bin/env bash

gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)";

./configure \
    "--build=${gnuArch}" \
    "--prefix=/etc/php" \
    "--with-apxs2=/usr/local/apache2/bin/apxs" \
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
