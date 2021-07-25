#!/usr/bin/env bash
set -Eeuo pipefail

cd /app/docker/apache-php8

# prepare directories for runtime files and logs
if [ ! -d /app/runtime ]; then
    mkdir /app/runtime
fi;
if [ ! -d /app/runtime/logs ]; then
    mkdir /app/runtime/logs
fi;

# configure SMTP with predefined configuration file
if [ -f msmtprc ]; then
    cp msmtprc /etc/msmtprc;
    chmod 600 /etc/msmtprc;
    chown www-data:www-data /etc/msmtprc;
# or use properties from .env file in project root
elif [ -f ../../.env ]; then
    LOG="/app/runtime/logs/msmtp.log";
    if [ -v SMTP_HOST ] && [ -v SMTP_USER ] && [ -v SMTP_PASSWORD ]; then
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
            echo "logfile $LOG";
        } >> /etc/msmtprc;
        chmod 600 /etc/msmtprc;
        chown www-data:www-data /etc/msmtprc;
    fi;
else
    echo "";
    echo "Sendmail is not configured through .env";
    echo "Define at least SMTP_HOST, SMTP_USER and SMTP_PASSWORD";
    echo "DISABLED" > /app/runtime/logs/msmtp.log;
    echo "";
fi;

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
if [ -f /app/php.env ]; then
    cat /app/php.env \
        | sed -E "s/^\s*([^#\s]+)\s*=\s*\"?([^\"]*)\"?\s*$/SetEnv \1 \"\2\"/" \
        | grep SetEnv \
        > /etc/apache2/conf-available/php-env-vars.conf
else
    touch /etc/apache2/conf-available/php-env-vars.conf
fi

# embed MySQL credentials from docker.env into php environment through Apache SetEnt
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
{ echo "SetEnv MYSQL_HOST \"$MYSQL_HOST\"";
  echo "SetEnv MYSQL_PORT \"$MYSQL_PORT\"";
  echo "SetEnv MYSQL_USER \"$MYSQL_USER\"";
  echo "SetEnv MYSQL_PASSWORD '$MYSQL_PASSWORD'";
  echo "SetEnv MYSQL_DATABASE \"$MYSQL_DATABASE\""; } >> /etc/apache2/conf-available/php-env-vars.conf

# configure php
cp php.ini /usr/local/etc/php/conf.d/docker.ini

# take care about access rights to runtime directory
chmod ugo+w /app/runtime
chmod ugo+w /app/runtime/logs

if [ ! -v PHP_ENABLE_XDEBUG ] || [ "$PHP_ENABLE_XDEBUG" != "1" ]; then
    if [ -f /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini ]; then
        # disable xdebug
        rm /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
    fi
fi

exec "$@"
