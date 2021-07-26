<?php

namespace app;

class Example
{
    public function __construct()
    {
        if (isset($_SERVER['REQUEST_METHOD']))
        {
            echo '<DOCTYPE html><html><head><title>Lampeton Example</title></head>';
            echo '<body><h1>List of databases:</h1><ul><li>';
            echo implode('</li><li>', $this->getDatabases());
            echo '</li></ul></body></html>';
        }
        else
        {
            echo 'List of databases: ' . PHP_EOL . '- ';
            echo implode(PHP_EOL . '- ', $this->getDatabases()) . PHP_EOL;
        }
    }

    protected function getDatabases()
    {
        $query = $this->getDb()->query('SHOW DATABASES');
        $databases = [];
        if ($query->execute())
        {
            foreach ($query->fetchAll() as $row) $databases[] = $row['Database'];
        }
        return $databases;
    }

    protected function getDb() {
        static $db;

        return $db ?: ($db = new \PDO(sprintf('mysql:host=%s;port=%s;dbname=%s',
            getenv('MYSQL_HOST'), getenv('MYSQL_PORT'), getenv('MYSQL_DATABASE')),
            getenv('MYSQL_USER'), getenv('MYSQL_PASSWORD')));
    }
}

if (!isset($_SERVER['REQUEST_METHOD'])) new Example();