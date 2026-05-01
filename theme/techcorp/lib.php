<?php

defined('MOODLE_INTERNAL') || die();

function theme_techcorp_get_main_scss_content($theme) {
    global $CFG;

    $scss = file_get_contents($CFG->dirroot . '/theme/boost/scss/preset/default.scss');
    $scss .= file_get_contents($CFG->dirroot . '/theme/techcorp/scss/techcorp.scss');

    return $scss;
}

function theme_techcorp_get_pre_scss($theme) {
    $pre = '';

    $pre .= '$primary: #1a365d;' . "\n";
    $pre .= '$secondary: #2b6cb0;' . "\n";
    $pre .= '$success: #276749;' . "\n";
    $pre .= '$info: #2c5282;' . "\n";
    $pre .= '$warning: #c05621;' . "\n";
    $pre .= '$danger: #c53030;' . "\n";
    $pre .= '$body-bg: #f7fafc;' . "\n";
    $pre .= '$navbar-dark-color: rgba(255,255,255,.9);' . "\n";
    $pre .= '$font-family-sans-serif: "Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;' . "\n";

    return $pre;
}

function theme_techcorp_get_extra_scss($theme) {
    return '';
}

function theme_techcorp_pluginfile($course, $cm, $context, $filearea, $args, $forcedownload, array $options = []) {
    if ($context->contextlevel == CONTEXT_SYSTEM && ($filearea === 'logo' || $filearea === 'backgroundimage')) {
        $theme = theme_config::load('techcorp');
        return $theme->setting_file_serve($filearea, $args, $forcedownload, $options);
    }
    send_file_not_found();
}
