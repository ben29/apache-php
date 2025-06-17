#!/bin/sh
set -e

APP_VERSION="2.0"
TAG="benhakim2010/php-apache:${APP_VERSION}"

docker build --progress=plain --no-cache --build-arg APP_VERSION=${APP_VERSION} -t "${TAG}" .
docker push "${TAG}"
docker push benhakim2010/php-apache:latest