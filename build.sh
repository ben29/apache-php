#!/usr/bin/env bash
git pull
docker rmi -f $(docker images -q)
docker build -t php-apache:1.0 .
docker tag php-apache:1.0 benhakim2010/php-apache:1.0
docker tag php-apache:1.0 benhakim2010/php-apache:latest
docker push benhakim2010/php-apache:1.0
docker push benhakim2010/php-apache:latest