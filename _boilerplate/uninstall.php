<?php
/**
 * Uninstall handler — runs when the plugin is deleted via WP admin.
 *
 * @package LEAStudios\PluginName
 */

// Exit if not called by WordPress.
if ( ! defined( 'WP_UNINSTALL_PLUGIN' ) ) {
	exit;
}

// Autoload.
if ( file_exists( __DIR__ . '/vendor/autoload.php' ) ) {
	require_once __DIR__ . '/vendor/autoload.php';
}

// Clean up options.
delete_option( 'plugin_name_options' );
delete_option( 'plugin_name_schema_version' );

// Drop custom tables.
// Uncomment to drop custom tables: LEAStudios\PluginName\Database\Migration::drop_tables().

// Clear any scheduled cron events.
$timestamp = wp_next_scheduled( 'plugin_name_cron_hook' );
if ( $timestamp ) {
	wp_unschedule_event( $timestamp, 'plugin_name_cron_hook' );
}

// Flush rewrite rules.
flush_rewrite_rules();
