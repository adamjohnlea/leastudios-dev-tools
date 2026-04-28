<?php
/**
 * Database migration handler.
 *
 * @package LEAStudios\PluginName\Database
 */

declare(strict_types=1);

namespace LEAStudios\PluginName\Database;

/**
 * Handles custom database table creation and migration.
 */
class Migration {

	/**
	 * The current schema version option key.
	 */
	private const SCHEMA_VERSION_KEY = 'plugin_name_schema_version';

	/**
	 * The target schema version.
	 */
	private const SCHEMA_VERSION = 1;

	/**
	 * Run migrations if needed.
	 *
	 * @return void
	 */
	public function maybe_migrate(): void {
		$current_version = (int) get_option( self::SCHEMA_VERSION_KEY, 0 );

		if ( $current_version >= self::SCHEMA_VERSION ) {
			return;
		}

		$this->migrate( $current_version );

		update_option( self::SCHEMA_VERSION_KEY, self::SCHEMA_VERSION );
	}

	/**
	 * Run the migration sequence.
	 *
	 * @param int $from_version Current schema version.
	 * @return void
	 */
	private function migrate( int $from_version ): void {
		global $wpdb;

		require_once ABSPATH . 'wp-admin/includes/upgrade.php';

		if ( $from_version < 1 ) {
			$this->create_initial_tables( $wpdb );
		}

		// Add further migration steps as needed.
	}

	/**
	 * Create initial database tables.
	 *
	 * @param \wpdb $wpdb WordPress database abstraction.
	 * @return void
	 */
	private function create_initial_tables( \wpdb $wpdb ): void {
		$charset_collate = $wpdb->get_charset_collate();
		$table_name      = $wpdb->prefix . 'plugin_name_items';

		$sql = "CREATE TABLE {$table_name} (
			id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
			title varchar(255) NOT NULL DEFAULT '',
			status varchar(20) NOT NULL DEFAULT 'active',
			created_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
			updated_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			PRIMARY KEY (id),
			KEY status (status)
		) {$charset_collate};";

		dbDelta( $sql );
	}

	/**
	 * Drop all plugin tables. Use on uninstall only.
	 *
	 * @return void
	 */
	public static function drop_tables(): void {
		global $wpdb;

		// phpcs:ignore WordPress.DB.DirectDatabaseQuery.SchemaChange
		$wpdb->query( "DROP TABLE IF EXISTS {$wpdb->prefix}plugin_name_items" );

		delete_option( self::SCHEMA_VERSION_KEY );
	}
}
