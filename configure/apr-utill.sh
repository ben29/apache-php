#!/usr/bin/env bash

./configure \
    "--bindir=/usr/bin" \
    "--sbindir=/usr/sbin" \
    "--includedir=/usr/include/apr-until" \
    "--libexecdir=/usr/local/libexec" \
    "--libdir=/lib64" \
    "--with-apr=/usr" \
    "--disable-util-dso"
