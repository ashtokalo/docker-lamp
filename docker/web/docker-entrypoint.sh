#!/usr/bin/env bash
set -Eeuo pipefail
cd /app/docker/web

# update timezone if required
if [ "$TZ" != `cat /etc/timezone` ]; then
  unlink /etc/localtime;
  ln -snf /usr/share/zoneinfo/$TZ /etc/localtime;
  echo $TZ > /etc/timezone
fi

################################################################################
##
## Prepare directories for runtime files and logs
##
################################################################################
if [ ! -d /app/runtime ]; then
    mkdir /app/runtime
fi;
if [ ! -d /app/logs ]; then
    mkdir /app/logs
fi;
chmod ugo+w /app/runtime
chmod ugo+w /app/logs

################################################################################
##
## Configure SMTP client msmtp
##
## - check on configuration file msmtprc;
## - or compose msmtprc from SMTP_* properties at docker.env
##
################################################################################
if [ -f /app/config/msmtprc ]; then
    cp /app/config/msmtprc /etc/msmtprc;
elif [ -v SMTP_HOST ] && [ -v SMTP_USER ] && [ -v SMTP_PASSWORD ]; then
    if [ ! -v SMTP_PORT ]; then
        SMTP_PORT=25;
    fi;
    if [ ! -v SMTP_FROM ]; then
        SMTP_FROM="$SMTP_USER";
    fi;
    if [ "$SMTP_PORT" == "587" ]; then
        {   echo "tls on";
            echo "tls_starttls on";
            echo "tls_certcheck on";
        } >> /etc/msmtprc;
    fi;
    {   echo "host $SMTP_HOST";
        echo "port $SMTP_PORT";
        echo "user $SMTP_USER";
        echo "pasword $SMTP_PASSWORD";
        echo "from $SMTP_FROM";
        echo "auth on";
        echo "logfile /app/logs/msmtp.log";
    } >> /etc/msmtprc;
else
    echo "msmtp: not configured properly";
fi;
# file must belongs to user who will send emails
if [ -f /etc/msmtprc ]; then
    chmod 600 /etc/msmtprc;
    chown www-data:www-data /etc/msmtprc;
fi

################################################################################
##
## Configure Apache httpd
##
################################################################################
if [ ! -v ADMIN_EMAIL ]; then
    ADMIN_EMAIL="admin@example.com"
fi
if [ ! -v HOST_NAME ]; then
    HOST_NAME="localhost"
fi
# configure default site in Apache
cat 000-default.conf \
    | sed "s/admin@example\.com/$ADMIN_EMAIL/" \
    | sed "s/localhost/$HOST_NAME/" \
    > /etc/apache2/sites-enabled/000-default.conf
# embed all options from php.env into php environment through Apache SetEnt
if [ -f /app/config/php.env ]; then
    cat /app/config/php.env \
        | sed -E "s/^\s*([^#\s]+)\s*=\s*\"?([^\"]*)\"?\s*$/SetEnv \1 \"\2\"/" \
        | grep SetEnv \
        > /etc/apache2/conf-available/php-env-vars.conf
else
    touch /etc/apache2/conf-available/php-env-vars.conf
fi
# embed MySQL credentials into php environment through Apache SetEnt
if [ ! -v MYSQL_HOST ]; then
    MYSQL_HOST="mysql"
fi
if [ ! -v MYSQL_PORT ]; then
    MYSQL_PORT="3306"
fi
if [ ! -v MYSQL_USER ]; then
    MYSQL_USER="root"
fi
if [ ! -v MYSQL_PASSWORD ]; then
    MYSQL_PASSWORD=""
fi
if [ ! -v MYSQL_DATABASE ]; then
    MYSQL_DATABASE="dbname"
fi
{ echo "SetEnv DB_TYPE 'mysql'";
  echo "SetEnv DB_HOST '$MYSQL_HOST'";
  echo "SetEnv DB_PORT '$MYSQL_HOST'";
  echo "SetEnv DB_USER '$MYSQL_USER'";
  echo "SetEnv DB_PASSWORD '$MYSQL_PASSWORD'";
  echo "SetEnv DB_DATABASE '$MYSQL_DATABASE'";
  echo "SetEnv DB_DSN 'mysql:host=$MYSQL_HOST;port=$MYSQL_PORT;dbname=$MYSQL_DATABASE'";
} >> /etc/apache2/conf-available/php-env-vars.conf

################################################################################
##
## Configure PHP
##
################################################################################

cp php.ini /usr/local/etc/php/conf.d/lampeton.ini
if [ -f /app/config/php.ini ]; then
  cp /app/config/php.ini /usr/local/etc/php/conf.d/lampeton-app.ini
elif [ -f /usr/local/etc/php/conf.d/lampeton-app.ini ]; then
  rm /usr/local/etc/php/conf.d/lampeton-app.ini
fi

if [ -f /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini ]; then
    rm /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
fi
if [ ! -v PHP_XDEBUG_PORT ]; then
    PHP_XDEBUG_PORT=9055
fi
if [ ! -v PHP_XDEBUG_IDEKEY ]; then
    PHP_XDEBUG_IDEKEY=LAMPETON
fi
if [ -v PHP_ENABLE_XDEBUG ] && [ "$PHP_ENABLE_XDEBUG" == "1" ]; then
  docker-php-ext-enable xdebug
  { echo "[xdebug]";
    echo "xdebug.remote_enable=1";
    echo "xdebug.remote_port=9055";
    echo "xdebug.remote_connect_back=1";
    echo "xdebug.remote_autostart=1";
    echo "xdebug.idekey=LAMPETON";
  } >> /usr/local/etc/php/conf.d/docker-xdebug.ini;
fi

# configure error logging - https://www.php.net/manual/en/errorfunc.constants.php
{ echo 'error_reporting = E_ERROR | E_WARNING | E_PARSE | E_CORE_ERROR | E_CORE_WARNING | E_COMPILE_ERROR | E_COMPILE_WARNING | E_RECOVERABLE_ERROR'; \
  echo 'display_errors = Off'; \
  echo 'display_startup_errors = Off'; \
  echo 'log_errors = On'; \
  echo 'error_log = /app/logs/php-error.log'; \
  echo 'log_errors_max_len = 1024'; \
  echo 'ignore_repeated_errors = On'; \
  echo 'ignore_repeated_source = Off'; \
  echo 'html_errors = Off'; \
  echo "date.timezone = $TZ"; \
} > /usr/local/etc/php/conf.d/error-logging.ini

# unset all environment variables used only to start docker
for ENV_VAR_NAME in SMTP_HOST SMTP_PORT SMTP_USER SMTP_PASSWORD SMTP_FROM \
   ADMIN_EMAIL HOST_NAME PHP_ENABLE_XDEBUG PHP_XDEBUG_PORT PHP_XDEBUG_IDEKEY \
   MYSQL_PORT MYSQL_HOST MYSQL_USER MYSQL_PASSWORD MYSQL_DATABASE; \
   do unset $ENV_VAR_NAME; done;

exec "$@"
