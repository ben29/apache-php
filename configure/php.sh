#!/usr/bin/env sh

export CFLAGS="-fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64"
export CPPFLAGS="$CFLAGS"
export LDFLAGS="-Wl,-O1 -pie -Wl,-z,stack-size=0x80000"

# Run PHP configure with modules and options
./configure \
    "--prefix=/etc/php" \
    "--bindir=/usr/local/bin" \
    "--sbindir=/usr/local/bin" \
    "--with-config-file-scan-dir=/etc" \
    "--disable-all" \
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
    "--disable-opcache-jit" \
    "--disable-cgi" \
    "--disable-phpdbg" \
    "--disable-ipv6"