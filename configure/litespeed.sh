#!/usr/bin/env bash

# DEPEND = brotli-devel
./configure \
  --enable-spdy=yes \
  --enable-http2=yes \
  --enable-recaptcha=yes \
  --with-user=nobdy \
  --with-group=nobody \
  --with-admin=admin \
  --with-adminport=7080 \
  --with-password='Ben159852' \
  --with-email='root@localhost' \
  --with-exampleport=8088 \
  --with-lsphp7 \
  --with-tempdir=/tmp/lshttpd \
  --with-lscpd=yes \
  --with-brotli=/