Lampeton
========

The LAMP application skeleton in docker environment to start development easy.

This project provides application templates for different frameworks and
scenarios. These templates let start development with well prepared environment
and concentrate on idea. Each template is a separate branch with specific
options. All branches based on main, which is most simple.

## Directory Structure

```
docker                   contains resources to build docker environments
    apache-php8          contains Apache httpd in conjunction with PHP
runtime                  contains files generated during runtime
    logs                 contains logs from Apache, PHP and SMTP services
web                      contains the entry script and Web resources
```

## Basic Environment

Application uses docker with at least two basic services `web` and `mysql`.

The `web` services is a Debian's Apache httpd in conjunction with PHP 8.0
(as mod_php) and uses mpm_prefork by default. It also contains SMTP client
[msmtp][1] to let send emails from php with built-in function mail(). The `web`
directory of the project used as a document root in Apache, so all other
files are never available through HTTP. Any request of file or directory that
doesn't exists will be redirected to `web/index.php`, so you can process the
request as you wish.

There are few environment variables in `web` service used to share some options:

- `TIMEZONE` - name of system TIMEZONE, by default is `UTC`;
- `MYSQL_HOST` - the hostname of MySQL, by defailt is `mysql`;
- `MYSQL_PORT` - port number to connect to MySQL, by default is `3306`;
- `MYSQL_USER` - user to connect to MySQL, by default is `root`;
- `MYSQL_PASSWORD` - password to connect to MySQL, by default is empty;
- `MYSQL_DATABASE` - name of database in MySQL, by default is `dbname`.

All options from `app.env` in project root also available as environment
variables in PHP. See `app.env.dist` for example.

Apache writes logs to `./runtime/logs/apache-error.log` and
`./runtime/logs/apache-access.log`. PHP logs could be found in
`./runtime/logs/php-error.log`.

The `mysql` service uses [native MySQL image][https://hub.docker.com/_/mysql/]
version 5.7 to setup database. All files stored in `./runtime/mysql`. The
database is available in command line through command like
`docker-compose exec mysql mysql dbname`.

SMTP service could be configured through variables like `SMTP_*` in `docker.env`
at project root. See `docker.env.dist` for example.

[1]: https://github.com/tpn/msmtp