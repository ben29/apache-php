#!/usr/bin/env bash

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
    --disable-app
