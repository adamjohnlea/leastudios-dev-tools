<?php
/**
 * Settings page handler.
 *
 * @package LEAStudios\PluginName\Admin
 */

declare(strict_types=1);

namespace LEAStudios\PluginName\Admin;

/**
 * Registers and renders the plugin settings page.
 */
class Settings_Page {

	/**
	 * The option group name.
	 */
	private const OPTION_GROUP = 'plugin_name_settings';

	/**
	 * The option name in the database.
	 */
	private const OPTION_NAME = 'plugin_name_options';

	/**
	 * The required capability to access settings.
	 */
	private const CAPABILITY = 'manage_options';

	/**
	 * Register hooks.
	 *
	 * @return void
	 */
	public function init(): void {
		add_action( 'admin_menu', [ $this, 'add_menu_page' ] );
		add_action( 'admin_init', [ $this, 'register_settings' ] );
	}

	/**
	 * Add the settings page to the admin menu.
	 *
	 * @return void
	 */
	public function add_menu_page(): void {
		add_options_page(
			__( 'Plugin Name Settings', 'plugin-name' ),
			__( 'Plugin Name', 'plugin-name' ),
			self::CAPABILITY,
			'plugin-name',
			[ $this, 'render_page' ]
		);
	}

	/**
	 * Register settings using the Settings API.
	 *
	 * @return void
	 */
	public function register_settings(): void {
		register_setting(
			self::OPTION_GROUP,
			self::OPTION_NAME,
			[
				'type'              => 'array',
				'sanitize_callback' => [ $this, 'sanitize_options' ],
				'default'           => $this->get_defaults(),
			]
		);

		add_settings_section(
			'plugin_name_general',
			__( 'General Settings', 'plugin-name' ),
			'__return_empty_string',
			'plugin-name'
		);
	}

	/**
	 * Sanitize options before saving.
	 *
	 * @param array<string, mixed> $input Raw input values.
	 * @return array<string, mixed> Sanitized values.
	 */
	public function sanitize_options( array $input ): array {
		$sanitized = [];

		// Sanitize each field from $input explicitly.

		return $sanitized;
	}

	/**
	 * Render the settings page.
	 *
	 * @return void
	 */
	public function render_page(): void {
		if ( ! current_user_can( self::CAPABILITY ) ) {
			return;
		}

		?>
		<div class="wrap">
			<h1><?php echo esc_html( get_admin_page_title() ); ?></h1>
			<form action="options.php" method="post">
				<?php
				settings_fields( self::OPTION_GROUP );
				do_settings_sections( 'plugin-name' );
				submit_button();
				?>
			</form>
		</div>
		<?php
	}

	/**
	 * Get default option values.
	 *
	 * @return array<string, mixed>
	 */
	private function get_defaults(): array {
		return [];
	}
}
