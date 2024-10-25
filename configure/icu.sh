#!/usr/bin/env bash

./configure \
    "--prefix=/usr/local/icu" \
    "--bindir=/usr/bin" \
    "--sbindir=/usr/sbin" \
    "--includedir=/usr/include/icu" \
    "--libexecdir=/usr/lib/icu" \
    "--libdir=/usr/lib/icu"
