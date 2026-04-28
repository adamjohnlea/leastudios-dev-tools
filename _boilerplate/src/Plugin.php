<?php
/**
 * Main plugin class.
 *
 * @package LEAStudios\PluginName
 */

declare(strict_types=1);

namespace LEAStudios\PluginName;

/**
 * Plugin bootstrap class.
 */
final class Plugin {

	/**
	 * Initialize the plugin components.
	 *
	 * @return void
	 */
	public function init(): void {
		$this->register_hooks();

		if ( is_admin() ) {
			$this->init_admin();
		}
	}

	/**
	 * Register WordPress hooks.
	 *
	 * @return void
	 */
	private function register_hooks(): void {
		add_action( 'init', [ $this, 'load_textdomain' ] );
		add_action( 'wp_enqueue_scripts', [ $this, 'enqueue_frontend_assets' ] );
	}

	/**
	 * Initialize admin-specific functionality.
	 *
	 * @return void
	 */
	private function init_admin(): void {
		add_action( 'admin_enqueue_scripts', [ $this, 'enqueue_admin_assets' ] );
	}

	/**
	 * Load plugin text domain for translations.
	 *
	 * @return void
	 */
	public function load_textdomain(): void {
		load_plugin_textdomain(
			'plugin-name',
			false,
			dirname( plugin_basename( PLUGIN_NAME_FILE ) ) . '/languages'
		);
	}

	/**
	 * Enqueue frontend scripts and styles.
	 *
	 * @return void
	 */
	public function enqueue_frontend_assets(): void {
		// Enqueue frontend assets here as needed.
	}

	/**
	 * Enqueue admin scripts and styles.
	 *
	 * @return void
	 */
	public function enqueue_admin_assets(): void {
		// Enqueue admin assets here as needed.
	}
}
