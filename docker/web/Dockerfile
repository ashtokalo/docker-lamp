ARG PHP_IMAGE_VERSION=8.0
FROM php:${PHP_IMAGE_VERSION}-apache
MAINTAINER Alexey Shtokalo <alexey@shtokalo.net>

# persistent dependencies
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends

# configure timezone
ARG TZ=UTC
RUN set -ex; \
    unlink /etc/localtime; \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime; \
    echo $TZ > /etc/timezone

# install light SMTP client for mail support
RUN set -ex; \
    apt-get install -y -q --no-install-recommends msmtp msmtp-mta

# install system packages for most used PHP extensions
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions \
    soap \
    zip \
    bcmath \
    exif \
    gd \
    intl \
    opcache \
    pdo_mysql \
    imagick \
    mongodb \
    xdebug

# configure environment
ENV COMPOSER_ALLOW_SUPERUSER=1 \
    TZ=$TZ \
    PHP_ENABLE_XDEBUG=0 \
    PATH=/app:/app/vendor/bin:/root/.composer/vendor/bin:$PATH \
    TERM=linux

# install composer
RUN curl -sS https://getcomposer.org/installer | php -- \
    --version=2.1.3 \
    --filename=composer.phar \
    --install-dir=/usr/local/bin && \
    { echo "#!/usr/bin/env bash"; \
      echo 'composer.phar "$@"'; } > /usr/local/bin/composer && \
    chmod ugo+x /usr/local/bin/composer && \
    composer clear-cache
   
# configure Apache modules - mod_rewrite, mod_headers, mod_expires, mod_remoteip
RUN set -eux; \
    a2enmod rewrite headers expires remoteip; \
    { \
    echo 'RemoteIPHeader X-Forwarded-For'; \
# these IP ranges are reserved for "private" use and should thus *usually* be safe inside Docker
    echo 'RemoteIPTrustedProxy 10.0.0.0/8'; \
    echo 'RemoteIPTrustedProxy 172.16.0.0/12'; \
    echo 'RemoteIPTrustedProxy 192.168.0.0/16'; \
    echo 'RemoteIPTrustedProxy 169.254.0.0/16'; \
    echo 'RemoteIPTrustedProxy 127.0.0.0/8'; \
    } > /etc/apache2/conf-available/remoteip.conf; \
    a2enconf remoteip; \
# replace all instances of "%h" with "%a" in LogFormat
    find /etc/apache2 -type f -name '*.conf' -exec sed -ri 's/([[:space:]]*LogFormat[[:space:]]+"[^"]*)%h([^"]*")/\1%a\2/g' '{}' +

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN set -eux; \
    docker-php-ext-enable opcache; \
    { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=2'; \
        echo 'opcache.fast_shutdown=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

# configure error logging
RUN { \
# https://www.php.net/manual/en/errorfunc.constants.php
    echo 'error_reporting = E_ERROR | E_WARNING | E_PARSE | E_CORE_ERROR | E_CORE_WARNING | E_COMPILE_ERROR | E_COMPILE_WARNING | E_RECOVERABLE_ERROR'; \
    echo 'display_errors = Off'; \
    echo 'display_startup_errors = Off'; \
    echo 'log_errors = On'; \
    echo 'error_log = /app/runtime/logs/php-error.log'; \
    echo 'log_errors_max_len = 1024'; \
    echo 'ignore_repeated_errors = On'; \
    echo 'ignore_repeated_source = Off'; \
    echo 'html_errors = Off'; \
    } > /usr/local/etc/php/conf.d/error-logging.ini

# cleanup
RUN apt-get clean; \
    rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*

VOLUME /app

COPY docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["apache2-foreground"]
