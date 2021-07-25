Lampeton
========

The LAMP application skeleton in docker environment to start development easy.

This template provides classic LAMP docker-environment to code any PHP project.
It has only two services `web` and `db`. The `web` is a Debian's Apache httpd in
conjunction with PHP 8.0 or 7.4 (as mod_php) and uses mpm_prefork by default.
The `db` is a MySQL 5.7 with one database.

The [other templates](https://github.com/ashtokalo/lampeton/branches) available as well.

## Directory Structure

```
config      contains all configuration files
docker      contains resources to build docker environments
    web     contains Apache httpd in conjunction with PHP
runtime     contains files generated during runtime, the only writable directory
    logs    contains logs from Apache, PHP and SMTP services
src         contains the application code
web         contains the entry script and Web resources
```

## Installation

It would better to use [Composer](http://getcomposer.org/) to start development.
You can try with following following command:

    composer create-project -s dev --prefer-dist ashtokalo/lampeton app

The command creates directory `app` (you can choose a different one) with this
project template. Otherwise, you can download and extract files from main branch
of [repository](https://github.com/ashtokalo/lampeton).

Finally, you can start project immediately with docker command:

    docker-compose up

or in background mode:

    docker-compose up -d

It might takes a time at first start because it need to build an image for the
`web` and `db` services.

## Template

The PHP works as mod_php in conjunction with Apache and most popular modules.
A few environment variables contains helpful details to connect to database:

- `MYSQL_DSN` - PHP PDO data source name;
- `MYSQL_HOST` - the hostname of MySQL, by defailt is `mysql`;
- `MYSQL_PORT` - port number to connect to MySQL, by default is `3306`;
- `MYSQL_USER` - user to connect to MySQL, by default is `root`;
- `MYSQL_PASSWORD` - password to connect to MySQL, by default is empty;
- `MYSQL_DATABASE` - name of database in MySQL, by default is `dbname`.

The `web` directory of the project used as a document root in Apache, so all
other files are never available through HTTP. Any request of file or directory
that doesn't exists will be redirected to `web/index.php`, so you can process
the request as you wish.

Built-in PHP function mail() might be used to send email if valid SMTP
credentials provided in SMTP_* variables at
[docker-compose.override.yml](./docker/docker-compose.override.yml.sample).

The project available at default HTTP port 80, as well as MySQL at 3306. Default
project timezone is UTC. These and other values might be changed through
`docker-compose.override.yml` mentioned above.

Directory `runtime` created at startup and is only writable by PHP to be used
as storage for temporary files, cache, etc.

There is also `runtime/logs` used for logs:

- `runtime/logs/apache-access.log` - combined Apache requests log
- `runtime/logs/apache-error.log` - Apache error log
- `runtime/logs/php-error.log` - PHP error log
- `runtime/logs/msmtp.log` - sendmail ([msmtp](https://github.com/tpn/msmtp)) log

You might want to run php application from command line with commend:

    docker-compose exec web src/some.php

To access MySQL you can run following command:

    docker-compose exec db mysql

Root password is empty by default. You might want to use any other client to get
access to the database.

## Contributing

Contributions are welcome and accepted via pull requests on [Github](https://github.com/ashtokalo/lampeton):

- **Document any change in behaviour** - Make sure the `README.md` and any other relevant documentation are kept up-to-date.

- **Create feature branches** - Don't ask to pull from your main branch.

- **One pull request per feature** - If you want to do more than one thing, send multiple pull requests.

- **Send coherent history** - Make sure each individual commit in your pull request is meaningful.
If you had to make multiple intermediate commits while developing, please [squash them](http://www.git-scm.com/book/en/v2/Git-Tools-Rewriting-History#Changing-Multiple-Commit-Messages) before submitting.

## License

The MIT License (MIT). Refer to the [License](LICENSE) for more information.