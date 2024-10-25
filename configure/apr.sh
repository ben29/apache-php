#!/usr/bin/env bash

./configure \
    "--bindir=/usr/bin" \
    "--sbindir=/usr/sbin" \
    "--includedir=/usr/include/apr" \
    "--libexecdir=/usr/local/libexec" \
    "--libdir=/lib64/apr" \
    "--disable-lfs" \
    "--disable-dso" \
    "--disable-timedlocks" \
    "--disable-ipv6"
