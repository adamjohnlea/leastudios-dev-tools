<?php
/**
 * Plugin Name:       Plugin Name
 * Plugin URI:        https://leastudios.com/plugins/plugin-name
 * Description:       A brief description of the plugin.
 * Version:           1.0.0
 * Requires at least: 6.4
 * Requires PHP:      8.2
 * Author:            leaStudios
 * Author URI:        https://leastudios.com
 * License:           GPL-2.0-or-later
 * License URI:       https://www.gnu.org/licenses/gpl-2.0.html
 * Text Domain:       plugin-name
 * Domain Path:       /languages
 *
 * @package LEAStudios\PluginName
 */

declare(strict_types=1);

// Prevent direct access.
defined( 'ABSPATH' ) || exit;

// Plugin constants.
// Derive the version from the plugin header so the runtime constant can
// never drift from the version shipped in the release zip.
define(
	'PLUGIN_NAME_VERSION',
	get_file_data( __FILE__, [ 'Version' => 'Version' ] )['Version']
);
define( 'PLUGIN_NAME_FILE', __FILE__ );
define( 'PLUGIN_NAME_DIR', plugin_dir_path( __FILE__ ) );
define( 'PLUGIN_NAME_URL', plugin_dir_url( __FILE__ ) );

// Autoloader.
if ( file_exists( __DIR__ . '/vendor/autoload.php' ) ) {
	require_once __DIR__ . '/vendor/autoload.php';
}

/**
 * Initialize the plugin.
 *
 * @return void
 */
function plugin_name_init(): void {
	// Check minimum requirements.
	if ( version_compare( PHP_VERSION, '8.2', '<' ) ) {
		add_action( 'admin_notices', 'plugin_name_php_version_notice' );
		return;
	}

	// Boot the plugin.
	$plugin = new LEAStudios\PluginName\Plugin();
	$plugin->init();
}
add_action( 'plugins_loaded', 'plugin_name_init' );

/**
 * Display PHP version notice.
 *
 * @return void
 */
function plugin_name_php_version_notice(): void {
	printf(
		'<div class="notice notice-error"><p>%s</p></div>',
		esc_html__( 'Plugin Name requires PHP 8.2 or higher.', 'plugin-name' )
	);
}

/**
 * Run on plugin activation.
 *
 * @return void
 */
function plugin_name_activate(): void {
	// Activation tasks (create tables, set options, etc.).
}
register_activation_hook( __FILE__, 'plugin_name_activate' );

/**
 * Run on plugin deactivation.
 *
 * @return void
 */
function plugin_name_deactivate(): void {
	// Deactivation cleanup.
}
register_deactivation_hook( __FILE__, 'plugin_name_deactivate' );
