FROM php:7.2-apache
#Install imagemagick
RUN apt-get update \
    && apt-get install imagemagick mariadb-client -y \
    && rm -rf /var/lib/apt/lists/*
RUN docker-php-ext-install pdo pdo_mysql mysqli
RUN a2enmod rewrite
COPY src/ /var/www/html/
COPY script/* /usr/local/bin/
ENV ENABLE_CACHE=1 \
    MYSQL_HOST=mariadb \
    MYSQL_DATABASE=visualcube \
    MYSQL_PASSWORD=visualcube \
    MYSQL_ROOT_PASSWORD=rootpw \
    CACHE_IMG_SIZE_LIMIT=10000
EXPOSE 80
CMD [ "docker-entrypoint.sh" ]
