<?php
/*
Plugin Name: FS Ensure WooCommerce
Description: Guarantees WooCommerce is activated on first load if present.
Version: 0.1.0
*/

add_action('plugins_loaded', function () {
    if (get_option('fs_ensure_wc_done')) {
        return;
    }
    if (!function_exists('is_plugin_active')) {
        require_once ABSPATH . 'wp-admin/includes/plugin.php';
    }
    $wc_plugin = 'woocommerce/woocommerce.php';
    $wc_path = WP_PLUGIN_DIR . '/woocommerce/woocommerce.php';
    if (file_exists($wc_path) && !is_plugin_active($wc_plugin)) {
        activate_plugin($wc_plugin, '', false, true);
    }
    if (function_exists('is_plugin_active') && is_plugin_active($wc_plugin)) {
        update_option('fs_bootstrap_wc_done', 1);
        update_option('fs_ensure_wc_done', 1);
    }
});
