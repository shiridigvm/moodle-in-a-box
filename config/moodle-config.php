<?php

unset($CFG);
global $CFG;
$CFG = new stdClass();

$CFG->dbtype    = 'mariadb';
$CFG->dblibrary = 'native';
$CFG->dbhost    = getenv('MOODLE_DATABASE_HOST') ?: 'db';
$CFG->dbname    = getenv('MOODLE_DATABASE_NAME') ?: 'moodle';
$CFG->dbuser    = getenv('MOODLE_DATABASE_USER') ?: 'moodle';
$CFG->dbpass    = getenv('MOODLE_DATABASE_PASSWORD') ?: '';
$CFG->prefix    = 'mdl_';
$CFG->dboptions = [
    'dbcollation' => 'utf8mb4_unicode_ci',
];

$CFG->wwwroot   = getenv('MOODLE_WWWROOT') ?: 'http://localhost';
$CFG->dataroot  = '/var/www/moodledata';
$CFG->admin     = 'admin';
$CFG->directorypermissions = 02777;

// Redis session handling
$redis_host = getenv('REDIS_HOST') ?: 'redis';
$CFG->session_handler_class = '\core\session\redis';
$CFG->session_redis_host = $redis_host;
$CFG->session_redis_port = 6379;
$CFG->session_redis_database = 0;
$CFG->session_redis_prefix = 'moodle_sess_';
$CFG->session_redis_acquire_lock_timeout = 120;
$CFG->session_redis_lock_expire = 7200;

// Redis MUC (Moodle Universal Cache)
$CFG->alternative_cache_factory_class = 'tool_forcedcache\\cache_factory';

// Performance
$CFG->cachejs = true;
$CFG->langstringcache = true;
$CFG->localcachedir = '/tmp/moodle-local-cache';

// Security
$CFG->passwordpolicy = true;
$CFG->passwordminlen = 12;
$CFG->loginhttps = false; // handled by nginx
$CFG->cookiesecure = (strpos($CFG->wwwroot, 'https://') === 0);
$CFG->cookiehttponly = true;

// Reverse proxy
$CFG->reverseproxy = true;
$CFG->sslproxy = (strpos($CFG->wwwroot, 'https://') === 0);

require_once(__DIR__ . '/lib/setup.php');
