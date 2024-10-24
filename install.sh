#!/usr/bin/env bash

ENV PHPIZE_DEPS gcc g++ make libexpat1-dev
ENV APR https://dlcdn.apache.org/apr/apr-1.7.5.tar.gz
ENV APR-UTIL https://dlcdn.apache.org//apr/apr-util-1.6.3.tar.gz

# persistent / runtime deps
RUN set -eux; \
  mkdir /usr/local/src; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		$PHPIZE_DEPS \
	; \
	rm -rf /var/lib/apt/lists/*

# INSTALL APR
RUN set -eux; \
  cd /usr/local/src; \
  wget $APR; \
  tar zvxf apr-1.7.5.tar.gz; \
  cd apr-1.7.5; \
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
    ; \
    make && make install;

# INSTALL APR Util
RUN set -eux; \
  cd /usr/local/src; \
  wget $APR-UTIL; \
  tar zvxf apr-util-1.6.3; \
  cd apr-util; \
  ./configure \
    "--bindir=/usr/bin" \
    "--sbindir=/usr/sbin" \
    "--includedir=/usr/include/apr-until" \
    "--libexecdir=/usr/local/libexec" \
    "--libdir=/lib64" \
    "--with-apr=/usr" \
    "--disable-util-dso"
    ; \
    make && make install;