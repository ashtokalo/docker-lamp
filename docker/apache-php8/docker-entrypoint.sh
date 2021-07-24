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
    ENV="/app/.env";
    LOG="/app/runtime/logs/msmtp.log";
    export $(grep -v '^#' "$ENV" | xargs -d '\n');
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

# configure default site in apache
cp 000-default.conf /etc/apache2/sites-enabled/000-default.conf

# configure php
cp php.ini /usr/local/etc/php/conf.d/docker.ini

# take care about access righs to runtime directory
chmod ugo+w /app/runtime
chmod ugo+w /app/runtime/logs

exec "$@"
