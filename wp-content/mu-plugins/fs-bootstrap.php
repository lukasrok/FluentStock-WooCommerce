<?php
/*
Plugin Name: FS Bootstrap
Description: One-time bootstrap to set sane permalinks and flush rewrites for this dev environment.
Version: 0.1.0
*/

add_action('init', function () {
    if (get_option('fs_bootstrap_done')) {
        return;
    }

    $desired = '/%postname%/';
    if (get_option('permalink_structure') !== $desired) {
        update_option('permalink_structure', $desired);
    }

    if (function_exists('flush_rewrite_rules')) {
        flush_rewrite_rules();
    }

    update_option('fs_bootstrap_done', 1);
});
