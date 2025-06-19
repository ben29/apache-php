#!/bin/sh
set -e

APP_VERSION="1.0"
TAG="benhakim2010/apache-php:${APP_VERSION}"

docker build --progress=plain --no-cache --build-arg APP_VERSION=${APP_VERSION} -t "${TAG}" .
docker push "${TAG}"