<?php
/**
 * Sample test for Plugin Name.
 *
 * Copy this file and modify for your plugin's tests.
 *
 * @package LEAStudios\PluginName\Tests
 */

declare(strict_types=1);

namespace LEAStudios\PluginName\Tests;

use LEAStudios\Tests\TestCase;

/**
 * Sample test class.
 */
class SampleTest extends TestCase {

	public function test_plugin_is_active(): void {
		$this->assertTrue( is_plugin_active( 'plugin-name/plugin-name.php' ) );
	}
}
