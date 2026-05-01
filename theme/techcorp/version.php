<?php

defined('MOODLE_INTERNAL') || die();

$plugin->version   = 2025042800;
$plugin->requires  = 2024042200; // Moodle 4.4+
$plugin->component = 'theme_techcorp';
$plugin->maturity  = MATURITY_STABLE;
$plugin->release   = '1.0.0';
$plugin->dependencies = [
    'theme_boost' => 2024042200,
];
