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
runtime     contains files generated during runtime
logs        contains logs from Apache, PHP and SMTP services
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

It might takes a time at first start because it need to download images for the
`web` and `db` services.

## Usage

The template assumes that all project source code will be stored to `src`
directory and only entry script `index.php` and some static resources will be
placed to the `web` directory. The `web` directory of the project used as a
document root in Apache, so all other files are never available through HTTP.
Any request of file or directory at [http://localhost] will be redirected to
`web/index.php` if they doesn't exists. The default HTTP port is 80 and it's
subject to configure.

Configuration files might be placed to `config` directory to keep them all in
one place. You might start with `config/php.env` with key-value properties to
configure application. These values will be available through PHP `getenv()`
through Apache SetEnv.

A few more environment variables available by default:

- `MYSQL_HOST` - the hostname of MySQL, by default is `mysql`;
- `MYSQL_PORT` - port number to connect to MySQL, by default is `3306`;
- `MYSQL_USER` - user to connect to MySQL, by default is `root`;
- `MYSQL_PASSWORD` - password to connect to MySQL, by default is empty;
- `MYSQL_DATABASE` - name of database in MySQL, by default is `dbname`.

Directory `runtime` used as storage for runtime resources, like cache, uploaded
files, etc. By default there is only one directory `runtime/mysql` used by
`mysql` service to store the database files. This directory created at startup.

All services and application logs might be stored into `logs` directory. This
directory created at startup and might contains following files:

- `logs/apache-access.log` - combined Apache requests log
- `logs/apache-error.log` - Apache error log
- `logs/php-error.log` - PHP error log
- `logs/msmtp.log` - sendmail ([msmtp](https://github.com/tpn/msmtp)) log

The PHP works as mod_php in conjunction with Apache and most popular modules
in docker container `web`. By default container uses pre-built image from docker
hub. You might want change the image or it's features, so the image sources
available at `docker\web`. The image includes [SMTP client](https://github.com/tpn/msmtp)
and allows to use `sendmail` in command line and `mail()` function in PHP to
send emails if valid SMTP credentials provided in `docker-compose.yml`.

Most options might be changed by overriding `docker-compose.yml`. Check on
[sample config](./docker-compose.override.yml.sample). You need copy the file to
`docker-compose.override.yml` to make changes here. Changing PHP version or
timezone might requires image building:

    docker-compose build

Other changes requires project restarting:

    docker-compose down
    docker-compose up

You might want to run some application script from command line with commend:

    docker-compose exec web php src/Example.php

To access MySQL you can run following command:

    docker-compose exec db mysql

Root password is empty by default. You might want to use any other client to get
access to the database.

The project already contains latest Composer with PSR-4 autoload mapping and
`src` directory is mapped to `app` namespace. Don't forget to change project
name, description and author in `composer.json` to yours. Happy coding!

## Contributing

Contributions are welcome and accepted via pull requests on [Github](https://github.com/ashtokalo/lampeton):

- **Document any change in behaviour** - Make sure the `README.md` and any other
relevant documentation are kept up-to-date.

- **Create feature branches** - Don't ask to pull from your main branch.

- **One pull request per feature** - If you want to do more than one thing, send
multiple pull requests.

- **Send coherent history** - Make sure each individual commit in your pull
request is meaningful. If you had to make multiple intermediate commits while
developing, please [squash them](http://www.git-scm.com/book/en/v2/Git-Tools-Rewriting-History#Changing-Multiple-Commit-Messages) before submitting.

## License

The MIT License (MIT). Refer to the [License](LICENSE) for more information.